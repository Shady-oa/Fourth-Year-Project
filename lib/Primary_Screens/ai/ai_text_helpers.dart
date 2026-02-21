import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Urbanist style helper ─────────────────────────────────────────────────────
/// Mirrors the weight conventions in createTextTheme() so the chat UI
/// automatically looks consistent with the rest of the app.
TextStyle aiUrbanist({
  double size = 12,
  FontWeight weight = FontWeight.w600,
  Color? color,
  double height = 1.55,
  TextDecoration decoration = TextDecoration.none,
  Color? decorationColor,
}) => GoogleFonts.urbanist(
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: height,
  decoration: decoration,
  decorationColor: decorationColor,
);

// ─── Text cleaning ─────────────────────────────────────────────────────────────
/// Strips stray single `*` that are NOT part of a `**` pair.
/// Leaves `**bold**` formatting fully intact.
String cleanAiText(String text) =>
    text.replaceAllMapped(RegExp(r'(?<!\*)\*(?!\*)'), (_) => '');

// ─── Formatted text parser ─────────────────────────────────────────────────────
/// **text**  → bold Urbanist w700
/// [text]    → bold + underline Urbanist w700
/// plain     → regular Urbanist w600
List<TextSpan> parseFormattedText(String raw, {required Color textColor}) {
  final text = cleanAiText(raw);
  final List<TextSpan> spans = [];
  final pattern = RegExp(r'\*\*(.+?)\*\*|\[(.+?)\]');
  int lastEnd = 0;

  for (final match in pattern.allMatches(text)) {
    // Plain text before this match
    if (match.start > lastEnd) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd, match.start),
          style: aiUrbanist(color: textColor),
        ),
      );
    }

    if (match.group(1) != null) {
      // **bold**
      spans.add(
        TextSpan(
          text: match.group(1),
          style: aiUrbanist(weight: FontWeight.bold, color: textColor),
        ),
      );
    } else if (match.group(2) != null) {
      // [bold + underline]
      spans.add(
        TextSpan(
          text: match.group(2),
          style: aiUrbanist(
            weight: FontWeight.bold,
            color: textColor,
            decoration: TextDecoration.underline,
            decorationColor: textColor,
          ),
        ),
      );
    }

    lastEnd = match.end;
  }

  // Remaining plain text after the last match
  if (lastEnd < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(lastEnd),
        style: aiUrbanist(color: textColor),
      ),
    );
  }

  // Fallback: whole string as plain text
  if (spans.isEmpty) {
    spans.add(
      TextSpan(
        text: text,
        style: aiUrbanist(color: textColor),
      ),
    );
  }

  return spans;
}
