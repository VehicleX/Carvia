import 'dart:async';
import 'package:carvia/core/constants/api_keys.dart';
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AIMessage({required this.text, required this.isUser, required this.timestamp});
}

class AIService extends ChangeNotifier {
  static const String _defaultModel = 'gemini-2.5-flash';
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

  bool get _hasValidApiKey {
    final key = ApiKeys.geminiApiKey.trim();
    if (key.isEmpty) return false;
    final upperKey = key.toUpperCase();
    return !upperKey.contains('YOUR_') && !upperKey.contains('PLACEHOLDER');
  }

  void _initModel() {
    if (!_hasValidApiKey) {
      debugPrint("Warning: Gemini API Key not set.");
      return;
    }

    _model = GenerativeModel(
      model: _defaultModel,
      apiKey: ApiKeys.geminiApiKey,
    );
    _chatSession = _model?.startChat();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(AIMessage(text: text, isUser: true, timestamp: DateTime.now()));
    _isLoading = true;
    notifyListeners();

    try {
      if (_model == null || _chatSession == null) {
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

  Future<String> generateVehicleAIAnalysis(VehicleModel vehicle) async {
    if (!_hasValidApiKey) {
      return "Unlock full AI potential by providing a valid Gemini API Key. \n\nThis vehicle appears to be a good match based on standard criteria.";
    }

    try {
      final prompt = '''
      Analyze the following vehicle as a car expert named Carvia AI:
      Brand: ${vehicle.brand}
      Model: ${vehicle.model}
      Year: ${vehicle.year}
      Price: \$${vehicle.price}
      Mileage: ${vehicle.mileage} miles
      Fuel: ${vehicle.fuel}
      Transmission: ${vehicle.transmission}

      Provide a concise 3-4 sentence personalized analysis of why this car is a good purchase, its key strengths, and what kind of driver it suits best.
      ''';

      if (_model == null) _initModel();
      final response = await _model?.generateContent([Content.text(prompt)]);
      
      return response?.text ?? "This vehicle is a solid choice. It offers a good balance of performance and reliability.";
    } catch (e) {
      debugPrint("AI Analysis Error: $e");
      return "This vehicle looks like a great option. Make sure to check it out in person and take it for a test drive!";
    }
  }
}
