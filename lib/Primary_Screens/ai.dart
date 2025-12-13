import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

// --- Message Model ---
enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage(this.text, this.sender, this.timestamp);
}

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      "Hello! I'm Penny AI, your smart finance assistant. Ask me about your budget, savings goals, or spending habits!",
      MessageSender.ai,
      DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ChatMessage(
      "How much did I spend on groceries last month?",
      MessageSender.user,
      DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    ChatMessage(
      "You spent \$450.75 on groceries in November. Would you like a breakdown by store?",
      MessageSender.ai,
      DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          _controller.text.trim(),
          MessageSender.user,
          DateTime.now(),
        ),
      );
      _controller.clear();
    });

    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(
          ChatMessage(
            "I'm analyzing your data now. This may take a second...",
            MessageSender.ai,
            DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // --- Chat Bubble ---
  Widget _buildMessage(ChatMessage message) {
    final bool isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser),
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isUser ? 40 : 8,
                right: isUser ? 8 : 40,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? accentColor : brandGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: isUser
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.white,
                ),
              ),
            ),
          ),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

  // --- Avatar ---
  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: isUser ? accentColor.withOpacity(0.8) : brandGreen,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  // --- Input Bar ---
  Widget _buildInputWidget() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Ask Penny AI anything...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _handleSend,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: brandGreen,
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: CustomHeader(headerName: "Penny AI"),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          _buildInputWidget(),
        ],
      ),
    );
  }
}
