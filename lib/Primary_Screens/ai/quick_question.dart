import 'package:flutter/material.dart';

// ─── Pre-designed question model ─────────────────────────────────────────────
class QuickQuestion {
  final String label;
  final String prompt;
  final IconData icon;
  final Color color;

  const QuickQuestion({
    required this.label,
    required this.prompt,
    required this.icon,
    required this.color,
  });
}
