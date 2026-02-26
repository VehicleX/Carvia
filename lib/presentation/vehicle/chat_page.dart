import 'package:carvia/core/models/message_model.dart';
import 'package:carvia/core/services/chat_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String otherUserId;
  final String otherUserName;
  final String vehicleId;
  final String vehicleName;

  const ChatPage({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUserId,
    required this.otherUserName,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final cid = await _chatService.ensureChat(
      buyerId: widget.currentUserId,
      buyerName: widget.currentUserName,
      sellerId: widget.otherUserId,
      sellerName: widget.otherUserName,
      vehicleId: widget.vehicleId,
      vehicleName: widget.vehicleName,
    );
    if (mounted) setState(() => _chatId = cid);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _chatId == null || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    await _chatService.sendMessage(
      cid: _chatId!,
      senderId: widget.currentUserId,
      text: text,
    );
    setState(() => _sending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.vehicleName,
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: false,
      ),
      body: _chatId == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: _chatService.messagesStream(_chatId!),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final messages = snap.data ?? [];
                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4)),
                              SizedBox(height: 12),
                              Text('Say hello to ${widget.otherUserName}!',
                                  style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                            ],
                          ),
                        );
                      }
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _scrollToBottom());
                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (_, i) => _buildBubble(messages[i]),
                      );
                    },
                  ),
                ),
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildBubble(MessageModel msg) {
    final isMe = msg.senderId == widget.currentUserId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.onSurface : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.text,
                style: TextStyle(
                    color: isMe ? Theme.of(context).colorScheme.onSurface : null, fontSize: 14)),
            SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(msg.timestamp),
              style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                      : Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), shape: BoxShape.circle),
                child: _sending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary, strokeWidth: 2),
                      )
                    : Icon(Icons.send_rounded,
                        color: Theme.of(context).colorScheme.onSurface, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
