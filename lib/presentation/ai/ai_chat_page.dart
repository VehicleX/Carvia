import 'dart:convert';
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/ai_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _mentionQuery = "";
  bool _isMentioning = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final lastAtPos = text.lastIndexOf('@');
    // Ensure the @ is at the beginning or comes after a space
    if (lastAtPos != -1 && (lastAtPos == 0 || text[lastAtPos - 1] == ' ')) {
      final query = text.substring(lastAtPos + 1);
      setState(() {
        _isMentioning = true;
        _mentionQuery = query.toLowerCase();
      });
    } else {
      setState(() {
        _isMentioning = false;
        _mentionQuery = "";
      });
    }
  }

  void _insertMention(VehicleModel vehicle) {
    final text = _controller.text;
    final lastAtPos = text.lastIndexOf('@');
    if (lastAtPos != -1) {
      final newText = text.substring(0, lastAtPos) + "${vehicle.brand} ${vehicle.model} ";
      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: newText.length));
    }
    setState(() {
      _isMentioning = false;
      _mentionQuery = "";
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final aiService = Provider.of<AIService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Carvia AI Assistant", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildModeToggle(aiService),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 80),
                  reverse: false, // In a real chat we might reverse this, but AIMessage list appends sequentially
                  itemCount: aiService.messages.length,
                  itemBuilder: (context, index) {
                    final message = aiService.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
                if (_isMentioning) _buildMentionOverlay(),
              ],
            ),
          ),
          if (aiService.isLoading)
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 8),
                  child: const Text("Carvia AI is typing...").animate(onPlay: (controller) => controller.repeat()).fadeIn(duration: 500.ms).fadeOut(curve: Curves.easeInOut, duration: 800.ms),
                ),
              ],
            ),
          _buildInputArea(aiService),
        ],
      ),
    );
  }

  Widget _buildModeToggle(AIService aiService) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToggleBtn("Quick Mode", !aiService.isDetailedMode, () {
            if (aiService.isDetailedMode) aiService.toggleDetailedMode();
          }),
          const SizedBox(width: 12),
          _buildToggleBtn("Detailed Mode", aiService.isDetailedMode, () {
            if (!aiService.isDetailedMode) aiService.toggleDetailedMode();
          }),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(50) : AppColors.surface,
          border: Border.all(color: isActive ? AppColors.primary : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildMentionOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 10, offset: const Offset(0, -2))
          ],
        ),
        child: StreamBuilder<List<VehicleModel>>(
          stream: Provider.of<VehicleService>(context, listen: false).getAllVehiclesStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            
            final vehicles = snapshot.data!.where((v) {
              final fullName = "${v.brand} ${v.model}".toLowerCase();
              return fullName.contains(_mentionQuery);
            }).toList();

            if (vehicles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No vehicles match.", style: TextStyle(color: AppColors.textMuted)),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final v = vehicles[index];
                return ListTile(
                  leading: const Icon(Iconsax.car, color: AppColors.primary),
                  title: Text("${v.brand} ${v.model}", style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text("\$${v.price.toStringAsFixed(0)} • ${v.year}", style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  onTap: () => _insertMention(v),
                );
              },
            );
          },
        ),
      ).animate().slideY(begin: 1.0, curve: Curves.easeOut).fade(),
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.zero,
            ),
            boxShadow: [
              BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Text(
            message.text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ).animate().fade(duration: 300.ms).slideX(begin: 0.05, duration: 300.ms),
      );
    } 

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.zero,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: AiResponseSectionWidget(rawText: message.text),
      ).animate().fade(duration: 400.ms).slideX(begin: -0.05, duration: 400.ms),
    );
  }

  Widget _buildInputArea(AIService aiService) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: "Ask about vehicles or type '@' to tag...",
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: (val) => _sendMessage(aiService),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 24,
              child: IconButton(
                icon: const Icon(Iconsax.send_1, color: Colors.white, size: 20),
                onPressed: () => _sendMessage(aiService),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(AIService aiService) {
    if (_controller.text.trim().isNotEmpty) {
      aiService.sendMessage(_controller.text.trim());
      _controller.clear();
      setState(() {
        _isMentioning = false;
        _mentionQuery = "";
      });
    }
  }
}

class AiResponseSectionWidget extends StatelessWidget {
  final String rawText;

  const AiResponseSectionWidget({super.key, required this.rawText});

  @override
  Widget build(BuildContext context) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawText);
      final String? title = data['title'];
      final List<dynamic>? sections = data['sections'];

      if (title != null && sections != null && sections.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(color: AppColors.surfaceDark),
              ),
              ...sections.map((sec) {
                final heading = sec['heading'] ?? '';
                final List<dynamic> content = sec['content'] ?? [];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (heading.toString().isNotEmpty)
                        Text(
                          heading.toString(),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      const SizedBox(height: 8),
                      ...content.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                            Expanded(child: Text(item.toString(), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
                          ],
                        ),
                      )),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }
    } catch (e) {
      // JSON Parse Failed, fallback to stripped text rendering immediately below
    }

    // Advanced Regex Fallback format: Completely strip out raw markdown symbols if the AI fails JSON parsing unexpectedly
    String cleanText = rawText.replaceAll(RegExp(r'\*\*|__'), '') // remove bold markers
                              .replaceAll(RegExp(r'\*|_'), '')    // remove italic markers
                              .replaceAll('###', '')              // strip heading levels
                              .replaceAll('##', '')
                              .replaceAll('#', '')
                              .trim();
                              
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        cleanText,
        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.4),
      ),
    );
  }
}
