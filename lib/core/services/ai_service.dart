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
  bool _isDetailedMode = false;
  ChatSession? _chatSession;
  GenerativeModel? _model;

  List<AIMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isDetailedMode => _isDetailedMode;

  void toggleDetailedMode() {
    _isDetailedMode = !_isDetailedMode;
    notifyListeners();
  }

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
        String prompt = text;
        prompt += '''\n\n---
IMPORTANT SYSTEM INSTRUCTIONS:
You MUST respond ONLY with valid, raw JSON. Do NOT wrap the response in markdown blocks (like ```json), and do NOT use markdown formatting symbols (*, **, #) anywhere inside the JSON strings.
Strictly adhere to this exact JSON structure:
{
  "title": "Main topic title",
  "sections": [
    {
      "heading": "Section Heading",
      "content": [
        "Bullet point 1",
        "Bullet point 2"
      ]
    }
  ]
}''';
        
        if (_isDetailedMode) {
          prompt += "\nMODE: Detailed. Provide expanded, professional explanations, deep reasoning, pros/cons, and highly specific examples.";
        } else {
          prompt += "\nMODE: Quick. Provide very concise, short, punchy bullet points. Maximum 1 short sentence per bullet.";
        }

        final response = await _chatSession!.sendMessage(Content.text(prompt));
        
        if (response.text != null) {
          // Clean up potential markdown blocks if Gemini stubbornly includes them
          String cleanText = response.text!.trim();
          if (cleanText.startsWith('```json')) {
            cleanText = cleanText.substring(7);
          }
          if (cleanText.startsWith('```')) {
            cleanText = cleanText.substring(3);
          }
          if (cleanText.endsWith('```')) {
            cleanText = cleanText.substring(0, cleanText.length - 3);
          }
          _messages.add(AIMessage(text: cleanText.trim(), isUser: false, timestamp: DateTime.now()));
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
