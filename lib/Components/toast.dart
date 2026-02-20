import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── App Toast — global feedback system ───────────────────────────────────────
//
// Usage:
//   AppToast.success(context, 'Budget created!');
//   AppToast.error(context, 'Something went wrong');
//   AppToast.warning(context, 'Low balance detected');
//   AppToast.info(context, 'Transaction updated');
// ─────────────────────────────────────────────────────────────────────────────

class AppToast {
  // ─── Public convenience methods ───────────────────────────────────────────

  static void success(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.check_circle_rounded,
      accentColor: const Color(0xFF00D09E),
      bgLight: const Color(0xFFEAFBF5),
      bgDark: const Color(0xFF0D2B22),
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.error_rounded,
      accentColor: const Color(0xFFFF4C4C),
      bgLight: const Color(0xFFFFF0F0),
      bgDark: const Color(0xFF2B0D0D),
    );
  }

  static void warning(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.warning_rounded,
      accentColor: const Color(0xFFFFA500),
      bgLight: const Color(0xFFFFF8ED),
      bgDark: const Color(0xFF2B2000),
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      icon: Icons.info_rounded,
      accentColor: const Color(0xFF2196F3),
      bgLight: const Color(0xFFEEF6FF),
      bgDark: const Color(0xFF0D1A2B),
    );
  }

  // ─── Core show ────────────────────────────────────────────────────────────
  static void _show({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color accentColor,
    required Color bgLight,
    required Color bgDark,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? bgDark : bgLight;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 160,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 3),
        padding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    message,
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Legacy compatibility shim ────────────────────────────────────────────────
// Kept so any remaining calls to showCustomToast() still compile.
void showCustomToast({
  required BuildContext context,
  required String message,
  required Color backgroundColor,
  required IconData icon,
}) {
  AppToast.info(context, message);
}
