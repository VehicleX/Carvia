import 'dart:async';
import 'package:carvia/core/constants/api_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AIMessage({required this.text, required this.isUser, required this.timestamp});
}

class AIService extends ChangeNotifier {
  final List<AIMessage> _messages = [
    AIMessage(text: "Hi! I'm Carvia AI. I can help you find the perfect car, compare models, or check financing options. What are you looking for today?", isUser: false, timestamp: DateTime.now()),
  ];
  bool _isLoading = false;
  ChatSession? _chatSession;
  GenerativeModel? _model;

  List<AIMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  AIService() {
    _initModel();
  }

  void _initModel() {
    if (ApiKeys.geminiApiKey == "YOUR_API_KEY_HERE") {
      debugPrint("Warning: Gemini API Key not set.");
      return;
    }
    
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: ApiKeys.geminiApiKey,
    );
    _chatSession = _model!.startChat();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(AIMessage(text: text, isUser: true, timestamp: DateTime.now()));
    _isLoading = true;
    notifyListeners();

    try {
      if (_model == null) {
        // Fallback or Error if API Key is missing
        await Future.delayed(const Duration(seconds: 1));
        _messages.add(AIMessage(text: "I'm currently in demo mode because my API Key isn't configured. Please add a valid Gemini API Key in `lib/core/constants/api_keys.dart` to unlock my full potential!", isUser: false, timestamp: DateTime.now()));
      } else {
        final response = await _chatSession!.sendMessage(Content.text(text));
        
        if (response.text != null) {
          _messages.add(AIMessage(text: response.text!, isUser: false, timestamp: DateTime.now()));
        } else {
           _messages.add(AIMessage(text: "I'm having trouble connecting. Please try again.", isUser: false, timestamp: DateTime.now()));
        }
      }
    } catch (e) {
      debugPrint("AI Error: $e");
      _messages.add(AIMessage(text: "Sorry, I encountered an error. Please try again later.", isUser: false, timestamp: DateTime.now()));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
