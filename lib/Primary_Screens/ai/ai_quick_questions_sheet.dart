import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/ai/ai_text_helpers.dart';
import 'package:final_project/Primary_Screens/ai/quick_questions_data.dart';
import 'package:flutter/material.dart';

import 'ai_question_tile.dart';

// ─── Quick questions bottom sheet ─────────────────────────────────────────────
class AiQuickQuestionsSheet extends StatelessWidget {
  final void Function({String? displayText, String? aiPrompt}) onSend;

  const AiQuickQuestionsSheet({super.key, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 14, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Sheet header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: brandGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Insights',
                        style: aiUrbanist(
                          size: 16,
                          weight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Tap a question to ask Penny AI',
                        style: aiUrbanist(
                          size: 12,
                          weight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade200),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: kQuickQuestions.length,
                itemBuilder: (_, i) {
                  final q = kQuickQuestions[i];
                  return AiQuestionTile(
                    question: q,
                    onTap: () {
                      Navigator.pop(context);
                      onSend(displayText: q.prompt, aiPrompt: q.prompt);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
