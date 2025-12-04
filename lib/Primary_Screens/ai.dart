import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';

// --- Message Model ---
enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage(this.text, this.sender, this.timestamp);
}

// --- Penny AI Screen Widget ---
class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final TextEditingController _controller = TextEditingController();
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
      "Based on your transactions, you spent **\$450.75** on groceries in November. Would you like a breakdown by store?",
      MessageSender.ai,
      DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      _controller.text.trim(),
      MessageSender.user,
      DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
    });

    // Simulate AI response after a short delay
    Future.delayed(const Duration(seconds: 1), _simulateAiResponse);
  }

  void _simulateAiResponse() {
    final aiResponse = ChatMessage(
      "That's a great question! I'm processing that information now...",
      MessageSender.ai,
      DateTime.now(),
    );
    setState(() {
      _messages.add(aiResponse);
    });
  }

  // --- Message Bubble Widget ---
  Widget _buildMessage(ChatMessage message) {
    final bool isUser = message.sender == MessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
        padding: const EdgeInsets.all(12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? accentColor : brandGreen,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft: isUser
                ? const Radius.circular(16.0)
                : const Radius.circular(4.0),
            bottomRight: isUser
                ? const Radius.circular(4.0)
                : const Radius.circular(16.0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: kTextTheme.bodyLarge!.copyWith(
                color: isUser
                    ? primaryText
                    : primaryBg, // Light text for AI, dark for user
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
              style: kTextTheme.bodySmall!.copyWith(
                color: isUser
                    ? primaryText.withOpacity(0.6)
                    : primaryBg.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Input Field Widget ---
  Widget _buildInputWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Ask penny AI about your finances...',
                border: const OutlineInputBorder(borderRadius: radiusLarge),
                fillColor: primaryText.withOpacity(0.1),
                filled: true,
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _handleSend,
            backgroundColor: primaryText,
            elevation: 0,
            mini: true,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBg,
        title: CustomHeader(headerName: "Penny AI"),
      ),
      backgroundColor: primaryBg,
      body: Column(
        children: <Widget>[
          // Chat Messages List
          Expanded(
            child: ListView.builder(
              reverse: false,
              padding: const EdgeInsets.only(top: 10.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),

          // Divider for visual separation

          // Input Widget
          _buildInputWidget(),
        ],
      ),
    );
  }
}
