// ============================================================
//  notification_icon.dart
//  Drop-in replacement for the Firebase-backed NotificationIcon.
//  Now reads unread count from local storage via NotificationService
//  — no Firebase dependency, fully offline.
// ============================================================

import 'package:final_project/Primary_Screens/Notifications/notification_services.dart';
import 'package:final_project/Primary_Screens/Notifications/notifications.dart';
import 'package:flutter/material.dart';

class NotificationIcon extends StatefulWidget {
  const NotificationIcon({super.key});

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  /// Reads the current unread count from SharedPreferences.
  Future<void> _refreshCount() async {
    final count = await NotificationService.unreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.circle_notifications_rounded,
            size: 30,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () async {
            // Navigate to the notifications page, then refresh the badge
            // count when the user returns (marks-as-read happens on that page).
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
            await _refreshCount();
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
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
                  _unreadCount > 9 ? '9+' : _unreadCount.toString(),
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
  }
}