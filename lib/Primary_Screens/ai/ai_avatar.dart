import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

// ─── Avatar widget ────────────────────────────────────────────────────────────
class AiAvatar extends StatelessWidget {
  final bool isUser;
  const AiAvatar({super.key, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isUser
            ? accentColor.withOpacity(0.15)
            : brandGreen.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: isUser
              ? accentColor.withOpacity(0.4)
              : brandGreen.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Icon(
        isUser ? Icons.person_outline : Icons.smart_toy_outlined,
        size: 16,
        color: isUser ? accentColor : brandGreen,
      ),
    );
  }
}
