import 'package:carvia/core/services/ai_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

// Assuming MainWrapper handles navigation to here via Drawer
// But since this is a "Feature", it might be a standalone page pushed from Drawer

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Only wrapping with ChangeNotifierProvider here if not global.
    // Plan says global registration? Or local. 
    // Let's use local provider for AI service to keep state fresh or global to persist chat?
    // User wants "Save conversation". Global is better or scoped to session.
    // I'll assume global registration for now to persist across navigation.
    
    final aiService = Provider.of<AIService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Carvia AI Assistant"),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () {
               // Clear chat?
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: aiService.messages.length,
              itemBuilder: (context, index) {
                final message = aiService.messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (aiService.isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(), 
            ),
          _buildInputArea(aiService),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isUser ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white),
        ),
      ),
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
                decoration: InputDecoration(
                  hintText: "Ask about cars...",
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (val) => _sendMessage(aiService),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: const Icon(Iconsax.send_1, color: Colors.white),
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
    }
  }
}
