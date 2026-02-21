import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/ai/ai_text_helpers.dart';
import 'package:final_project/Primary_Screens/ai/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


import 'ai_avatar.dart';
import 'ai_typing_indicator.dart';

// ─── Message Bubble ────────────────────────────────────────────────────────────
class AiMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const AiMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    // Text color derived from theme – adapts to light / dark mode automatically.
    final textColor = isUser
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                AiAvatar(isUser: false),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  // 80 % width gives AI long responses enough room without
                  // making user bubbles look like wall-of-text.
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.80,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    // User → accentColor (blue) from colors.dart
                    // AI   → surfaceVariant (theme-aware light/dark)
                    color: isUser
                        ? accentColor
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: message.isLoading
                      ? const AiTypingIndicator()
                      : RichText(
                          text: TextSpan(
                            children: isUser
                                ? [
                                    // User bubbles: plain Urbanist, no markdown.
                                    TextSpan(
                                      text: message.text,
                                      style: aiUrbanist(color: textColor),
                                    ),
                                  ]
                                : parseFormattedText(
                                    message.text,
                                    textColor: textColor,
                                  ),
                          ),
                        ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                AiAvatar(isUser: true),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 46,
              right: isUser ? 46 : 0,
            ),
            child: Text(
              timeStr,
              style: aiUrbanist(
                size: 10,
                weight: FontWeight.w500,
                color: Colors.grey.shade400,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
