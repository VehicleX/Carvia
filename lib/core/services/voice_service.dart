import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  bool _isListening = false;
  String _recognizedText = '';
  bool _speechEnabled = false;

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  VoiceService() {
    _initTts();
    _initSpeech();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (val) {
        debugPrint('Speech recognition error: \${val.errorMsg}');
        _isListening = false;
        notifyListeners();
      },
      onStatus: (val) {
        debugPrint('Speech recognition status: \$val');
        if (val == 'done' || val == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
    );
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  Future<bool> startListening() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint("Microphone permission denied.");
      return false;
    }

    if (!_speechEnabled) {
       _speechEnabled = await _speechToText.initialize();
    }

    if (_speechEnabled) {
      _recognizedText = '';
      _isListening = true;
      notifyListeners();

      await _speechToText.listen(
        onResult: (result) {
           // Only update text while actively listening to prevent late empty updates
           if (_isListening) {
             _recognizedText = result.recognizedWords;
             notifyListeners();
           }
        },
        listenFor: const Duration(seconds: 45), // Keep listening for longer phrases
        pauseFor: const Duration(seconds: 4),  // Allow 4 seconds of silence before auto-stopping
        partialResults: true,                  // Show words as they are spoken
        cancelOnError: true,
        listenMode: ListenMode.dictation,      // Dictation mode is better for continuous speech
      );
      return true;
    }
    return false;
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    }
  }
}
