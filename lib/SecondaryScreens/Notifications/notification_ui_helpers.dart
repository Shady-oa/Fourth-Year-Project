import 'package:final_project/SecondaryScreens/Notifications/notification_type.dart';
import 'package:flutter/material.dart';

// ─── Notification Type UI extensions ─────────────────────────────────────────
extension NotifTypeUI on NotificationType {
  // Icon per notification type — color is handled uniformly by the theme.
  IconData get icon {
    switch (this) {
      case NotificationType.budget:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.savings:
        return Icons.savings_rounded;
      case NotificationType.streak:
        return Icons.local_fire_department_rounded;
      case NotificationType.analysis:
        return Icons.bar_chart_rounded;
      case NotificationType.report:
        return Icons.receipt_long_rounded;
      case NotificationType.insight:
        return Icons.lightbulb_rounded;
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
    }
  }
}

// ─── Filter tab model ─────────────────────────────────────────────────────────
class NotificationFilterTab {
  final String label;
  final NotificationType? type; // null means "All"
  const NotificationFilterTab(this.label, this.type);
}

const notificationFilters = [
  NotificationFilterTab('All', null),
  NotificationFilterTab('Budget', NotificationType.budget),
  NotificationFilterTab('Savings', NotificationType.savings),
  NotificationFilterTab('Streak', NotificationType.streak),
  NotificationFilterTab('Reports', NotificationType.report),
  NotificationFilterTab('AI', NotificationType.insight),
  NotificationFilterTab('Reminders', NotificationType.reminder),
];