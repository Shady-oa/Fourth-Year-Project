
import 'package:final_project/SecondaryScreens/Notifications/app_notification.dart';
import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_type.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─── Notification Card ─────────────────────────────────────────────────────────
/// Renders a single notification as either a swipe-to-delete card (normal mode)
/// or a tap-to-select card (select mode). All interactions are delegated via
/// callbacks so state stays in [NotificationsPage].
class NotificationCard extends StatelessWidget {
  final AppNotification notif;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onEnterSelectMode;
  final VoidCallback onExitSelectMode;
  final Future<void> Function(String id) onDeleteSingle;
  final Future<void> Function() onMarkRead;

  const NotificationCard({
    super.key,
    required this.notif,
    required this.isSelectMode,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onEnterSelectMode,
    required this.onExitSelectMode,
    required this.onDeleteSingle,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final typeIcon = notif.type.icon;
    final isRead = notif.isRead;

    final cardBg = isSelected
        ? (isDark ? accent.withOpacity(0.18) : accent.withOpacity(0.09))
        : isRead
            ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
            : (isDark
                ? Color.alphaBlend(
                    accent.withOpacity(0.07),
                    const Color(0xFF1C1C1E),
                  )
                : Color.alphaBlend(accent.withOpacity(0.03), Colors.white));

    final timeStr = DateFormat('HH:mm').format(notif.createdAt);

    // In select mode — no Dismissible; just tap-to-toggle-select
    if (isSelectMode) {
      return GestureDetector(
        onTap: onToggleSelect,
        onLongPress: onExitSelectMode,
        child: _cardContent(
          theme,
          isDark,
          accent,
          typeIcon,
          isRead,
          cardBg,
          timeStr,
        ),
      );
    }

    // Normal mode — swipe-to-delete + long-press to enter select
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            const SizedBox(height: 3),
            Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await onDeleteSingle(notif.id);
        return false;
      },
      child: GestureDetector(
        onTap: () async {
          if (!isRead) {
            await LocalNotificationStore.markAsRead(notif.id);
            await onMarkRead();
          }
        },
        onLongPress: onEnterSelectMode,
        child: _cardContent(
          theme,
          isDark,
          accent,
          typeIcon,
          isRead,
          cardBg,
          timeStr,
        ),
      ),
    );
  }

  Widget _cardContent(
    ThemeData theme,
    bool isDark,
    Color accent,
    IconData typeIcon,
    bool isRead,
    Color cardBg,
    String timeStr,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected
              ? accent.withOpacity(0.55)
              : isDark
                  ? Colors.white.withOpacity(isRead ? 0.06 : 0.10)
                  : Colors.black.withOpacity(isRead ? 0.06 : 0.08),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Checkbox (select mode) or icon bubble ─────────────────────
            if (isSelectMode)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent
                      : accent.withOpacity(isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : typeIcon,
                  size: 24,
                  color: isSelected
                      ? Colors.white
                      : accent.withOpacity(isRead ? 0.5 : 0.9),
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isRead
                      ? accent.withOpacity(isDark ? 0.12 : 0.08)
                      : accent.withOpacity(isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  typeIcon,
                  size: 24,
                  color: accent.withOpacity(isRead ? 0.5 : 0.9),
                ),
              ),

            const SizedBox(width: 14),

            // ── Text content ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type pill + time + unread dot
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          notif.type.label.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark
                                ? Colors.white.withOpacity(0.40)
                                : Colors.black.withOpacity(0.35),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withOpacity(isRead ? 0.25 : 0.45)
                              : Colors.black.withOpacity(isRead ? 0.25 : 0.40),
                        ),
                      ),
                      if (!isRead && !isSelectMode) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.4),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 7),

                  // Title
                  Text(
                    notif.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      color: isDark
                          ? Colors.white.withOpacity(isRead ? 0.45 : 0.92)
                          : Colors.black.withOpacity(isRead ? 0.4 : 0.88),
                      height: 1.35,
                      letterSpacing: -0.2,
                    ),
                  ),

                  // Message body
                  if (notif.message.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      notif.message,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.55,
                        color: isDark
                            ? Colors.white.withOpacity(isRead ? 0.28 : 0.58)
                            : Colors.black.withOpacity(isRead ? 0.3 : 0.55),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
