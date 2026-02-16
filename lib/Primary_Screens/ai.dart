import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

// --- Message Model ---
enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage(this.text, this.sender, this.timestamp, {this.isLoading = false});
}

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String userUid = FirebaseAuth.instance.currentUser!.uid;

  // Local helper for typing animation or temporary state
  bool _isSending = false;

  // --- Call AI backend ---
  Future<String> _sendMessageToAI(String message, String userid) async {
    try {
      final response = await http.post(
        Uri.parse("https://fourth-year-backend.onrender.com/ai/chat"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userid,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? "Sorry, I didn't understand that.";
      } else {
        return "Error: AI backend returned ${response.statusCode}";
      }
    } catch (e) {
      return "Error connecting to AI backend: $e";
    }
  }

  // --- Handle sending a message ---
  void _handleSend() async {
    if (_controller.text.trim().isEmpty || _isSending || userUid.isEmpty) return;

    final userText = _controller.text.trim();
    _controller.clear();

    setState(() {
      _isSending = true;
    });

    _scrollToBottom();

    // Call backend (which will save both user and AI messages to Firestore)
    await _sendMessageToAI(userText, userUid);

    if (!mounted) return;
    setState(() {
      _isSending = false;
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- Chat Bubble (UI code remains identical) ---
  Widget _buildMessage(ChatMessage message) {
    final bool isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
              child: message.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      message.text,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: isUser ? Theme.of(context).colorScheme.onSurface : Colors.white,
                      ),
                    ),
            ),
          ),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

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

  Widget _buildInputWidget() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
              width: .5,
            ),
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
                  minLines: 1,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: "Ask Penny AI anything...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 8),
              if (_isSending)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: brandGreen),
                )
              else
                GestureDetector(
                  onTap: _handleSend,
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: brandGreen,
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
        title: const CustomHeader(headerName: "Penny AI"),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Listens to the exact path where your Node.js backend saves messages
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userUid)
                  .collection('chats')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                
                // Convert Firestore docs back into your ChatMessage model
                final messages = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ChatMessage(
                    data['content'] ?? "",
                    data['role'] == "user" ? MessageSender.user : MessageSender.ai,
                    (data['timestamp'] as Timestamp).toDate(),
                  );
                }).toList();

                // If history is empty, show your original welcome message
                if (messages.isEmpty) {
                  messages.add(ChatMessage(
                    "Hello! I'm Penny AI, your smart finance assistant. Ask me about your budget!",
                    MessageSender.ai,
                    DateTime.now(),
                  ));
                }

                // Automatic scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) => _buildMessage(messages[index]),
                );
              },
            ),
          ),
          _buildInputWidget(),
        ],
      ),
    );
  }
}