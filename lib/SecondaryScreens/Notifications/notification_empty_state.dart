import 'package:final_project/SecondaryScreens/Notifications/notification_ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Notification Empty State ─────────────────────────────────────────────────
class NotificationEmptyState extends StatelessWidget {
  final int filterIndex;

  const NotificationEmptyState({super.key, required this.filterIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 42,
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'All Caught Up!',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filterIndex == 0
                  ? 'Smart notifications will appear here\nas you use the app.'
                  : 'No ${notificationFilters[filterIndex].label} notifications yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withOpacity(0.25)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
