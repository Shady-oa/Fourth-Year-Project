import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/ai/ai_text_helpers.dart';
import 'package:flutter/material.dart';


// ─── Welcome Banner ────────────────────────────────────────────────────────────
class AiWelcomeBanner extends StatelessWidget {
  const AiWelcomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // brandGreen → accentColor matches the app's primary palette.
          colors: [brandGreen.withOpacity(0.85), accentColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: brandGreen.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello! I'm Penny AI",
                  style: aiUrbanist(
                    size: 16,
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your smart finance assistant. Tap ✨ or type to ask me anything about your finances.',
                  style: aiUrbanist(
                    size: 12,
                    weight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
