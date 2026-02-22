import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:final_project/SecondaryScreens/Notifications/notifications.dart';
import 'package:flutter/material.dart';

/// Bell icon button that shows a live unread-count badge.
///
/// Uses [LocalNotificationStore.unreadCountNotifier] — no network/Firestore
/// required. The badge updates immediately whenever a notification is saved
/// or marked as read anywhere in the app.
class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LocalNotificationStore.unreadCountNotifier,
      builder: (context, unreadCount, _) {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: IconButton(
                icon: Icon(
                  Icons.circle_notifications_rounded,
                  size: 34,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                  // Refresh count when returning from notification page
                  await LocalNotificationStore.init();
                },
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 30,
                top: 26,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
