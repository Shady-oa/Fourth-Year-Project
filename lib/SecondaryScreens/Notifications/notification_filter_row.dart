import 'package:final_project/SecondaryScreens/Notifications/notification_ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Notification Filter Row ──────────────────────────────────────────────────
/// Horizontal scrollable pill-filter row for the Notifications page.
class NotificationFilterRow extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const NotificationFilterRow({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: notificationFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? accent : accent.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Text(
                notificationFilters[i].label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : accent.withOpacity(0.75),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
