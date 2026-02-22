// ─────────────────────────────────────────────────────────────────────────────
// SecondaryScreens/Reminders/reminder_scheduler.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:final_project/Components/toast.dart';
import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_type.dart';
import 'package:final_project/SecondaryScreens/Reminder/reminder_storage.dart';

import 'package:flutter/material.dart';

/// Checks all active reminders on every app open and fires any that are due.
/// Call [ReminderScheduler.runChecks] from [HomePage.initState], alongside
/// [SmartNotificationService.runAllChecks].
class ReminderScheduler {
  ReminderScheduler._();

  /// Runs through all reminders, fires any that are due, advances their
  /// nextTriggerDate, and shows a toast via [context] if provided.
  static Future<void> runChecks(BuildContext? context) async {
    final reminders = await ReminderStorage.fetchAll();
    final now = DateTime.now();

    for (final reminder in reminders) {
      if (!reminder.isActive) continue;
      if (reminder.nextTriggerDate.isAfter(now)) continue;

      // ── Push to Notifications page (type: reminder) ───────────────────
      await LocalNotificationStore.saveNotification(
        title: '⏰ Reminder: ${reminder.name}',
        message: reminder.description.isNotEmpty
            ? reminder.description
            : 'You have a scheduled financial reminder.',
        type: NotificationType.reminder,
        dedupKey: '${reminder.id}_${_dateKey(reminder.nextTriggerDate)}',
      );

      // ── Toast on the active page ───────────────────────────────────────
      if (context != null && context.mounted) {
        AppToast.info(context, '⏰ Reminder: ${reminder.name}');
      }

      // ── Advance to next trigger ────────────────────────────────────────
      final next = reminder.computeNextTrigger();
      await ReminderStorage.advanceTrigger(reminder.id, next);
    }
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
