import 'package:final_project/Primary_Screens/ai/quick_question.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


// ─── Question tile ────────────────────────────────────────────────────────────
class AiQuestionTile extends StatelessWidget {
  final QuickQuestion question;
  final VoidCallback onTap;

  const AiQuestionTile({super.key, required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: question.color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: question.color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: question.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(question.icon, color: question.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.label,
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: question.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    question.prompt,
                    style: GoogleFonts.urbanist(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
