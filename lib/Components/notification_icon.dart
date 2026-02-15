import 'package:final_project/Primary_Screens/notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final User user = FirebaseAuth.instance.currentUser!;
    String userId = user.uid;
    return IconButton(
      icon: Icon(
        Icons.circle_notifications_rounded,
        size: 30,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NotificationsPage(userId: userId),
          ),
        );
      },
    );
  }
}
