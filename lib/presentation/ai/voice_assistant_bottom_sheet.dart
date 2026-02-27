import 'dart:convert';
import 'package:carvia/core/services/ai_service.dart';
import 'package:carvia/core/services/voice_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class VoiceAssistantBottomSheet extends StatefulWidget {
  const VoiceAssistantBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceAssistantBottomSheet(),
    );
  }

  @override
  State<VoiceAssistantBottomSheet> createState() => _VoiceAssistantBottomSheetState();
}

class _VoiceAssistantBottomSheetState extends State<VoiceAssistantBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSpeakingAiResponse = false;
  bool _readAloudEnabled = true;
  String? _pendingAiTaskText;

  @override
  void initState() {
    super.initState();
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    voiceService.addListener(_onVoiceServiceUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startVoiceSession(voiceService);
    });
  }

  @override
  void dispose() {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    voiceService.removeListener(_onVoiceServiceUpdate);
    voiceService.stopListening();
    voiceService.stopSpeaking();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startVoiceSession(VoiceService voiceService) async {
    bool started = await voiceService.startListening();
    if (started) {
      _isSpeakingAiResponse = false;
    }
  }

  void _onVoiceServiceUpdate() {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    // Update text box if listening
    if (voiceService.isListening && voiceService.recognizedText.isNotEmpty) {
      _controller.text = voiceService.recognizedText;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    }

    // If the user manually stopped listening or the speech engine stopped listening on its own (silence)
    if (!voiceService.isListening && voiceService.recognizedText.isNotEmpty) {
      // Trigger submit automatically after a short delay to allow UI to catch up
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _controller.text.isNotEmpty) {
           _triggerAiSubmit(voiceService);
        }
      });
    }
  }

  void _triggerAiSubmit(VoiceService voiceService) async {
    if (_controller.text.isEmpty) return;
    
    String prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    await voiceService.stopListening();
    
    _pendingAiTaskText = prompt;
    _controller.clear();
    setState(() {});

    final aiService = Provider.of<AIService>(context, listen: false);
    
    // Remember message count to detect addition
    final messageCountBefore = aiService.messages.length;
    await aiService.sendMessage(prompt);
    final messageCountAfter = aiService.messages.length;

    if (messageCountAfter > messageCountBefore) {
      final lastMsg = aiService.messages.last;
      if (!lastMsg.isUser) {
        setState(() {
          _isSpeakingAiResponse = true;
          _pendingAiTaskText = null;
        });
        
        // Strip markdown before speaking
        String speakableText = lastMsg.text
          .replaceAll(RegExp(r'\*\*|__'), '')
          .replaceAll(RegExp(r'\*|_'), '')
          .replaceAll(RegExp(r'[#`"\{\}\[\]]'), '')
          .replaceAll(RegExp(r'title|sections|heading|content|:'), '')
          .trim();
        
        if (_readAloudEnabled) {
          await voiceService.speak(speakableText);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = Provider.of<VoiceService>(context);
    final aiService = Provider.of<AIService>(context);

    // Get the latest conversational message for display
    AIMessage? displayMsg;
    if (aiService.messages.isNotEmpty) {
      displayMsg = aiService.messages.last;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Voice Assistant",
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _readAloudEnabled = !_readAloudEnabled;
                  });
                  if (!_readAloudEnabled) {
                    Provider.of<VoiceService>(context, listen: false).stopSpeaking();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _readAloudEnabled ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _readAloudEnabled ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_readAloudEnabled ? Iconsax.volume_high : Iconsax.volume_slash, 
                           size: 14, 
                           color: _readAloudEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text("Read Aloud", style: TextStyle(fontSize: 11, color: _readAloudEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(), // Scroll handled by parent
                          shrinkWrap: true,
                          itemCount: aiService.messages.length,
                          itemBuilder: (context, index) {
                            final msg = aiService.messages[index];
                            if (msg.isUser) {
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  margin: const EdgeInsets.only(bottom: 12, left: 32),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(msg.text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                ),
                              );
                            } else {
                              // AI Message Display
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12, right: 16),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Iconsax.magic_star, color: Theme.of(context).colorScheme.primary, size: 16),
                                          const SizedBox(width: 8),
                                          Text("AI Recommendation", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Builder(
                                        builder: (context) {
                                          try {
                                            final data = jsonDecode(msg.text);
                                            final title = data['title'] ?? '';
                                            final desc = data['disclaimer'] ?? '';
                                            // Handle sections properly
                                            final sections = data['sections'] as List<dynamic>? ?? [];
                                            
                                            // More detailed formatter for the bottom sheet
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (title.isNotEmpty) Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                if (title.isNotEmpty) const SizedBox(height: 8),
                                                
                                                ...sections.map((sec) {
                                                  final heading = sec['heading'] ?? '';
                                                  final content = sec['content'] as List<dynamic>? ?? [];
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 8.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        if (heading.toString().isNotEmpty)
                                                          Text(heading.toString(), style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                                                        ...content.map((c) => Padding(
                                                          padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                                                          child: Row(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                                                              Expanded(child: Text(c.toString(), style: TextStyle(fontSize: 13, height: 1.4))),
                                                            ],
                                                          ),
                                                        )),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                                
                                                if (desc.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                                                  const SizedBox(height: 4),
                                                  Text(desc, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11, fontStyle: FontStyle.italic)),
                                                ]
                                              ],
                                            );
                                          } catch (_) {
                                            return Text(
                                              msg.text.replaceAll(RegExp(r'\*\*|__'), '').replaceAll(RegExp(r'\*|_'), '').replaceAll(RegExp(r'[#`"\{\}\[\]]'), ''),
                                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, height: 1.4),
                                            );
                                          }
                                        }
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),

                  if (aiService.isLoading) ...[
                     Text("Thinking...").animate(onPlay: (controller) => controller.repeat()).fadeIn(duration: 500.ms).fadeOut(curve: Curves.easeInOut, duration: 800.ms),
                  ] else if (_isSpeakingAiResponse && displayMsg != null && !displayMsg.isUser) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Iconsax.magic_star, color: Theme.of(context).colorScheme.primary, size: 16),
                                const SizedBox(width: 8),
                                Text("AI Recommendation", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // For bottom sheet, we just show a simplified text version 
                            // Try parsing as JSON first to make it cleaner
                            Builder(
                              builder: (context) {
                                try {
                                  final data = jsonDecode(displayMsg!.text);
                                  final title = data['title'] ?? '';
                                  final desc = data['disclaimer'] ?? '';
                                  // Quick simple formatter
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (title.isNotEmpty) Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      if (title.isNotEmpty) const SizedBox(height: 8),
                                      Text(
                                        displayMsg!.text.replaceAll(RegExp(r'\*\*|__'), '').replaceAll(RegExp(r'\*|_'), '').replaceAll(RegExp(r'[#`"\{\}\[\]]'), ''),
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, height: 1.4),
                                      ),
                                      if (desc.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(desc, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 11, fontStyle: FontStyle.italic)),
                                      ]
                                    ],
                                  );
                                } catch (_) {
                                  return Text(
                                    displayMsg!.text.replaceAll(RegExp(r'\*\*|__'), '').replaceAll(RegExp(r'\*|_'), '').replaceAll(RegExp(r'[#`"\{\}\[\]]'), ''),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, height: 1.4),
                                  );
                                }
                              }
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade().slideY(),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: voiceService.isListening ? "Listening..." : "Type or speak...",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                    ),
                    onSubmitted: (_) => _triggerAiSubmit(voiceService),
                  ),
                ),
                if (!voiceService.isListening && _controller.text.isNotEmpty) ...[
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Iconsax.send_1, color: Colors.white, size: 18),
                    ),
                    onPressed: () => _triggerAiSubmit(voiceService),
                  ),
                ]
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Center(
            child: GestureDetector(
              onTap: () {
                if (voiceService.isListening) {
                  voiceService.stopListening();
                } else {
                  voiceService.stopSpeaking();
                  _startVoiceSession(voiceService);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: voiceService.isListening 
                      ? Theme.of(context).colorScheme.error 
                      : Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    if (voiceService.isListening)
                      BoxShadow(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                  ],
                ),
                child: Icon(
                  voiceService.isListening ? Iconsax.microphone_25 : Iconsax.microphone_2,
                  color: Colors.white,
                  size: 28,
                ),
              ).animate(target: voiceService.isListening ? 1 : 0).scaleXY(end: 1.1, duration: 600.ms, curve: Curves.easeInOut).then(delay: 100.ms).scaleXY(end: 1 / 1.1, duration: 600.ms, curve: Curves.easeInOut),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              voiceService.isListening ? "Tap to stop and analyze" : "Tap to speak",
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
