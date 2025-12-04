 import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/notifications.dart';
import 'package:flutter/material.dart';

class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.circle_notifications_rounded,
        size: 30,
        color: primaryText,
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const Notifications(),
          ),
        );
      },
    );
  }}