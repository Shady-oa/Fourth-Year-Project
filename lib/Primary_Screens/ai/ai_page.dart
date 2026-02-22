import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/ai/ai_constants.dart';
import 'package:final_project/Primary_Screens/ai/ai_input_widget.dart';
import 'package:final_project/Primary_Screens/ai/ai_message_bubble.dart';
import 'package:final_project/Primary_Screens/ai/ai_quick_questions_sheet.dart';
import 'package:final_project/Primary_Screens/ai/ai_service.dart';
import 'package:final_project/Primary_Screens/ai/ai_text_helpers.dart';
import 'package:final_project/Primary_Screens/ai/ai_welcome_banner.dart';
import 'package:final_project/Primary_Screens/ai/chat_message.dart';
import 'package:final_project/Primary_Screens/ai/quick_questions_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ─── AI Page ──────────────────────────────────────────────────────────────────
class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String userUid = FirebaseAuth.instance.currentUser!.uid;

  bool _isSending = false;
  bool _initialScrollDone = false;

  @override
  void initState() {
    super.initState();
    // Jump to the latest message immediately when the page first renders.
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Handle sending ────────────────────────────────────────────────────────
  void _handleSend({String? displayText, String? aiPrompt}) async {
    final userText = displayText ?? _controller.text.trim();
    final promptText = aiPrompt ?? userText;

    if (userText.isEmpty || _isSending) return;
    if (displayText == null) _controller.clear();

    setState(() => _isSending = true);

    // 1️⃣  Write the clean user bubble to Firestore immediately (optimistic UI).
    await AiService.saveUserMessageLocally(userUid, userText);
    _scrollToBottom();

    // 2️⃣  Call AI backend – backend saves AI reply to Firestore.
    //     Any enriched context bubble is filtered out in the StreamBuilder.
    final reply = await AiService.sendMessageToAI(
      userText,
      promptText,
      userUid,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (reply.startsWith('Error connecting to AI backend') ||
          reply.startsWith('Error: AI backend returned')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot reach Penny AI. Please check your internet connection.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
    _scrollToBottom();
  }

  // ─── Scroll helpers ────────────────────────────────────────────────────────

  /// Instant jump – avoids jarring top-to-bottom animation on page open.
  void _jumpToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  /// Smooth animated scroll – used after a new message arrives.
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

  // ─── Quick questions bottom sheet ─────────────────────────────────────────
  void _showQuestionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiQuickQuestionsSheet(onSend: _handleSend),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const CustomHeader(headerName: 'Penny AI'),
        actions: [
          Tooltip(
            message: 'Quick Insights',
            child: InkWell(
              onTap: _showQuestionsSheet,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: brandGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: brandGreen, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      'Ask',
                      style: aiUrbanist(
                        size: 13,
                        weight: FontWeight.w700,
                        color: brandGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userUid)
                  .collection('chats')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: aiUrbanist(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: brandGreen),
                  );
                }

                final docs = snapshot.data!.docs;

                // ── Filter out enriched-context bubbles saved by the backend.
                //    Only documents WITHOUT the sentinel header are rendered.
                final messages = docs
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final content = (data['content'] as String? ?? '').trim();
                      return !content.contains(kAiContextPrefix);
                    })
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final ts = data['timestamp'];
                      final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
                      return ChatMessage(
                        data['content'] ?? '',
                        data['role'] == 'user'
                            ? MessageSender.user
                            : MessageSender.ai,
                        dt,
                      );
                    })
                    .toList();

                final showWelcome = messages.isEmpty;

                // Jump (first load) or animate (new messages) to the bottom.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_initialScrollDone) {
                    _initialScrollDone = true;
                    _jumpToBottom();
                  } else {
                    _scrollToBottom();
                  }
                });

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  children: [
                    if (showWelcome) const AiWelcomeBanner(),
                    // Quick-start chips shown only on an empty chat.
                    if (showWelcome)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: kQuickQuestions.take(4).map((q) {
                            return GestureDetector(
                              onTap: () => _handleSend(
                                displayText: q.prompt,
                                aiPrompt: q.prompt,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: q.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: q.color.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(q.icon, color: q.color, size: 14),
                                    const SizedBox(width: 5),
                                    Text(
                                      q.label,
                                      style: aiUrbanist(
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: q.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ...messages.map((m) => AiMessageBubble(message: m)),
                    // Typing indicator while the AI is responding.
                    if (_isSending)
                      AiMessageBubble(
                        message: ChatMessage(
                          '',
                          MessageSender.ai,
                          DateTime.now(),
                          isLoading: true,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          AiInputWidget(
            controller: _controller,
            isSending: _isSending,
            onSend: _handleSend,
            onShowQuestionsSheet: _showQuestionsSheet,
          ),
        ],
      ),
    );
  }
}
