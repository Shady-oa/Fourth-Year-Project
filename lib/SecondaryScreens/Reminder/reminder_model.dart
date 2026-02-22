// ─────────────────────────────────────────────────────────────────────────────
// SecondaryScreens/Reminders/reminder_model.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:uuid/uuid.dart';

// ── Frequency Enum ────────────────────────────────────────────────────────────

enum ReminderFrequency { daily, weekly, monthly, custom }

extension ReminderFrequencyX on ReminderFrequency {
  String get value {
    switch (this) {
      case ReminderFrequency.daily:
        return 'daily';
      case ReminderFrequency.weekly:
        return 'weekly';
      case ReminderFrequency.monthly:
        return 'monthly';
      case ReminderFrequency.custom:
        return 'custom';
    }
  }

  String get label {
    switch (this) {
      case ReminderFrequency.daily:
        return 'Daily';
      case ReminderFrequency.weekly:
        return 'Weekly';
      case ReminderFrequency.monthly:
        return 'Monthly';
      case ReminderFrequency.custom:
        return 'Custom';
    }
  }

  static ReminderFrequency fromString(String? v) {
    switch (v) {
      case 'daily':
        return ReminderFrequency.daily;
      case 'weekly':
        return ReminderFrequency.weekly;
      case 'monthly':
        return ReminderFrequency.monthly;
      case 'custom':
        return ReminderFrequency.custom;
      default:
        return ReminderFrequency.monthly;
    }
  }
}

// ── Reminder Model ────────────────────────────────────────────────────────────

class Reminder {
  final String id;
  String name;
  String description;
  DateTime startDate;
  ReminderFrequency frequency;
  int customIntervalDays;

  /// Hour (0–23) at which this reminder should trigger each cycle.
  int triggerHour;

  /// Minute (0–59) at which this reminder should trigger each cycle.
  int triggerMinute;

  DateTime nextTriggerDate;
  DateTime createdAt;
  bool isActive;

  Reminder({
    String? id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.frequency,
    this.customIntervalDays = 1,
    this.triggerHour = 9,
    this.triggerMinute = 0,
    DateTime? nextTriggerDate,
    DateTime? createdAt,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       nextTriggerDate = nextTriggerDate ??
           _computeNext(
             startDate,
             frequency,
             customIntervalDays,
             triggerHour,
             triggerMinute,
           );

  // ── Time helpers ────────────────────────────────────────────────────────────

  /// Human-readable trigger time, e.g. "9:00 AM" or "3:45 PM".
  String get triggerTimeLabel {
    final period = triggerHour < 12 ? 'AM' : 'PM';
    final displayHour = triggerHour == 0
        ? 12
        : triggerHour > 12
            ? triggerHour - 12
            : triggerHour;
    final displayMinute = triggerMinute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  // ── Next-trigger computation ────────────────────────────────────────────────

  /// Advance [base] by one frequency unit and stamp the trigger time.
  static DateTime _addOneUnit(
    DateTime base,
    ReminderFrequency freq,
    int customDays,
    int hour,
    int minute,
  ) {
    DateTime next;
    switch (freq) {
      case ReminderFrequency.daily:
        next = base.add(const Duration(days: 1));
        break;
      case ReminderFrequency.weekly:
        next = base.add(const Duration(days: 7));
        break;
      case ReminderFrequency.monthly:
        next = DateTime(
          base.month == 12 ? base.year + 1 : base.year,
          base.month == 12 ? 1 : base.month + 1,
          base.day,
        );
        break;
      case ReminderFrequency.custom:
        next = base.add(Duration(days: customDays));
        break;
    }
    // Stamp the user-chosen time onto the advanced date
    return DateTime(next.year, next.month, next.day, hour, minute);
  }

  /// Compute the first future trigger from [base], respecting [hour]:[minute].
  static DateTime _computeNext(
    DateTime base,
    ReminderFrequency freq,
    int customDays,
    int hour,
    int minute,
  ) {
    final now = DateTime.now();
    // Start with the base date stamped at the chosen time
    DateTime next = DateTime(base.year, base.month, base.day, hour, minute);

    // Advance until strictly in the future
    while (!next.isAfter(now)) {
      next = _addOneUnit(next, freq, customDays, hour, minute);
    }
    return next;
  }

  /// Advance [nextTriggerDate] to the next slot after now, keeping trigger time.
  DateTime computeNextTrigger() => _computeNext(
        nextTriggerDate,
        frequency,
        customIntervalDays,
        triggerHour,
        triggerMinute,
      );

  // ── Serialisation ───────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'startDate': startDate.toIso8601String(),
        'frequency': frequency.value,
        'customIntervalDays': customIntervalDays,
        'triggerHour': triggerHour,
        'triggerMinute': triggerMinute,
        'nextTriggerDate': nextTriggerDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) {
    final freq = ReminderFrequencyX.fromString(json['frequency'] as String?);
    final customDays = (json['customIntervalDays'] as num?)?.toInt() ?? 1;
    final hour = (json['triggerHour'] as num?)?.toInt() ?? 9;
    final minute = (json['triggerMinute'] as num?)?.toInt() ?? 0;

    return Reminder(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      frequency: freq,
      customIntervalDays: customDays,
      triggerHour: hour,
      triggerMinute: minute,
      nextTriggerDate: json['nextTriggerDate'] != null
          ? DateTime.parse(json['nextTriggerDate'] as String)
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}