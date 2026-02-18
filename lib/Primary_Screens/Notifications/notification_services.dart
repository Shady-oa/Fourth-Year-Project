// ============================================================
//  notification_service.dart
//  Handles all local notification storage, retrieval, and
//  smart engagement notification generation.
//  No server dependency — fully offline.
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// FIX 1: Re-added the missing flutter_local_notifications import.
// Document 3 removed it but all plugin types (FlutterLocalNotificationsPlugin,
// AndroidNotificationDetails, DarwinNotificationDetails, Importance, Priority,
// AndroidFlutterLocalNotificationsPlugin, etc.) are still used throughout the
// file, causing "undefined class/identifier" compile errors without this import.
import 'package:shared_preferences/shared_preferences.dart';

// ─── Notification Type Enum ───────────────────────────────────────────────────
enum NotificationType {
  budget,
  savings,
  streak,
  analysis,
  report,
  inactivity,
  general,
}

extension NotificationTypeExt on NotificationType {
  String get key {
    switch (this) {
      case NotificationType.budget:
        return 'budget';
      case NotificationType.savings:
        return 'savings';
      case NotificationType.streak:
        return 'streak';
      case NotificationType.analysis:
        return 'analysis';
      case NotificationType.report:
        return 'report';
      case NotificationType.inactivity:
        return 'inactivity';
      case NotificationType.general:
        return 'general';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.budget:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.savings:
        return Icons.savings_outlined;
      case NotificationType.streak:
        return Icons.local_fire_department_outlined;
      case NotificationType.analysis:
        return Icons.insights_outlined;
      case NotificationType.report:
        return Icons.bar_chart_outlined;
      case NotificationType.inactivity:
        return Icons.notifications_active_outlined;
      case NotificationType.general:
        return Icons.notifications_outlined;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.budget:
        return const Color(0xFF5C6BC0);
      case NotificationType.savings:
        return const Color(0xFF43A047);
      case NotificationType.streak:
        return const Color(0xFFFF7043);
      case NotificationType.analysis:
        return const Color(0xFF7E57C2);
      case NotificationType.report:
        return const Color(0xFF26A69A);
      case NotificationType.inactivity:
        return const Color(0xFFEF5350);
      case NotificationType.general:
        return const Color(0xFF42A5F5);
    }
  }

  String get label {
    switch (this) {
      case NotificationType.budget:
        return 'Budget';
      case NotificationType.savings:
        return 'Savings';
      case NotificationType.streak:
        return 'Streak';
      case NotificationType.analysis:
        return 'Analysis';
      case NotificationType.report:
        return 'Report';
      case NotificationType.inactivity:
        return 'Reminder';
      case NotificationType.general:
        return 'General';
    }
  }
}

// Top-level helper — replaces the illegal static extension method.
// Dart extensions cannot have static members; this is the correct pattern.
NotificationType notificationTypeFromKey(String key) {
  switch (key) {
    case 'budget':
      return NotificationType.budget;
    case 'savings':
      return NotificationType.savings;
    case 'streak':
      return NotificationType.streak;
    case 'analysis':
      return NotificationType.analysis;
    case 'report':
      return NotificationType.report;
    case 'inactivity':
      return NotificationType.inactivity;
    default:
      return NotificationType.general;
  }
}

// ─── Local Notification Model ─────────────────────────────────────────────────
class LocalNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationType type;
  bool isRead;

  LocalNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'type': type.key,
        'isRead': isRead,
      };

  factory LocalNotification.fromMap(Map<String, dynamic> map) =>
      LocalNotification(
        id: map['id'] as String? ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: map['title'] as String? ?? '',
        message: map['message'] as String? ?? '',
        // Safe parse — falls back to now() instead of throwing.
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        // Uses the top-level function; static extension methods are illegal in Dart.
        type: notificationTypeFromKey(map['type'] as String? ?? 'general'),
        isRead: map['isRead'] as bool? ?? false,
      );
}

// ─── Notification Service ─────────────────────────────────────────────────────
class NotificationService {
  static const String _storageKey = 'local_notifications';
  static const String _lastActiveKey = 'last_active_date';
  static const String _lastInactivityNotifKey = 'last_inactivity_notif';
  static const int _maxNotifications = 100;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── Plugin Initialization ────────────────────────────────────────────────
  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // FIX 2: Restored `const` on DarwinInitializationSettings and
    // InitializationSettings. Document 3 changed these to `final` without
    // reason — they are compile-time constants and `const` is correct here.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;

    // Request POST_NOTIFICATIONS permission on Android 13+.
    // FIX 3: Wrapped in try/catch — requestNotificationsPermission() does not
    // exist on older plugin versions; without the guard the app crashes on
    // those devices.
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {
      // Permission API unavailable on this Android version — safe to ignore.
    }
  }

  // ── Device-Level Notification ────────────────────────────────────────────
  static Future<void> _showDeviceNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) async {
    if (!_initialized) await initialize();

    // FIX 4: Restored `const` on the detail objects. Document 3 removed all
    // `const` keywords here, which is legal but causes unnecessary allocations
    // on every call. These objects are structurally constant.
    const androidDetails = AndroidNotificationDetails(
      'penny_wise_channel',
      'Penny Wise Notifications',
      channelDescription: 'Smart financial insights and reminders',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Notification IDs must fit in a 32-bit int. Using remainder(100000)
    // keeps the value safely within range on all Android versions.
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // ── Core Storage Operations ───────────────────────────────────────────────

  /// Saves a notification and optionally fires a system tray alert.
  static Future<void> saveNotification({
    required String title,
    required String message,
    required NotificationType type,
    bool showDeviceNotification = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await fetchNotifications();

    // Deduplicate: skip identical title+message within the last hour.
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final isDuplicate = existing.any(
      (n) =>
          n.title == title &&
          n.message == message &&
          n.createdAt.isAfter(oneHourAgo),
    );
    if (isDuplicate) return;

    final newNotif = LocalNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      createdAt: DateTime.now(),
      type: type,
      isRead: false,
    );

    final trimmed = [newNotif, ...existing].take(_maxNotifications).toList();

    await prefs.setString(
      _storageKey,
      json.encode(trimmed.map((n) => n.toMap()).toList()),
    );

    if (showDeviceNotification) {
      await _showDeviceNotification(title: title, body: message, type: type);
    }
  }

  /// Returns all notifications from local storage, newest first.
  static Future<List<LocalNotification>> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => LocalNotification.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns notifications matching [type].
  static Future<List<LocalNotification>> fetchByType(
      NotificationType type) async {
    final all = await fetchNotifications();
    return all.where((n) => n.type == type).toList();
  }

  /// Marks a single notification as read.
  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await fetchNotifications();
    for (final n in all) {
      if (n.id == id) n.isRead = true;
    }
    await prefs.setString(
      _storageKey,
      json.encode(all.map((n) => n.toMap()).toList()),
    );
  }

  /// Marks every notification as read.
  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final all = await fetchNotifications();
    for (final n in all) {
      n.isRead = true;
    }
    await prefs.setString(
      _storageKey,
      json.encode(all.map((n) => n.toMap()).toList()),
    );
  }

  /// Deletes a single notification by [id].
  static Future<void> deleteNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await fetchNotifications();
    final updated = all.where((n) => n.id != id).toList();
    await prefs.setString(
      _storageKey,
      json.encode(updated.map((n) => n.toMap()).toList()),
    );
  }

  /// Deletes all notifications.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Returns the number of unread notifications.
  static Future<int> unreadCount() async {
    final all = await fetchNotifications();
    return all.where((n) => !n.isRead).length;
  }

  // ── Auto-delete ───────────────────────────────────────────────────────────
  /// Removes notifications older than [days] days (default 30).
  static Future<void> autoDeleteOld({int days = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await fetchNotifications();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final filtered = all.where((n) => n.createdAt.isAfter(cutoff)).toList();
    await prefs.setString(
      _storageKey,
      json.encode(filtered.map((n) => n.toMap()).toList()),
    );
  }

  // ── Last Active Tracking ─────────────────────────────────────────────────
  static Future<void> updateLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _lastActiveKey, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastActiveKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // ══════════════════════════════════════════════════════════
  //  SMART NOTIFICATION GENERATORS
  // ══════════════════════════════════════════════════════════

  // ── Budget ────────────────────────────────────────────────────────────────
  static Future<void> checkBudgetAlerts({
    required String budgetName,
    required double spent,
    required double total,
  }) async {
    if (total <= 0) return;
    final pct = (spent / total) * 100;

    if (pct >= 100) {
      await saveNotification(
        title: '🚨 Budget Overspent: $budgetName',
        message:
            'You\'ve exceeded your $budgetName budget by ${_fmt(spent - total)}. '
            'Total spent: ${_fmt(spent)} of ${_fmt(total)}.',
        type: NotificationType.budget,
        showDeviceNotification: true,
      );
    } else if (pct >= 90) {
      await saveNotification(
        title: '⚠️ Budget Critical: $budgetName',
        message: '90% of your $budgetName budget used. '
            'Only ${_fmt(total - spent)} remaining out of ${_fmt(total)}.',
        type: NotificationType.budget,
        showDeviceNotification: true,
      );
    } else if (pct >= 80) {
      await saveNotification(
        title: '📊 Budget Alert: $budgetName',
        message: '80% of your $budgetName budget has been used. '
            '${_fmt(total - spent)} left of ${_fmt(total)}.',
        type: NotificationType.budget,
      );
    }
  }

  // ── Savings ───────────────────────────────────────────────────────────────
  static Future<void> notifySavingsGoalAchieved(
      String goalName, double amount) async {
    await saveNotification(
      title: '🎉 Goal Achieved: $goalName!',
      message:
          'Congratulations! You\'ve successfully saved ${_fmt(amount)} and '
          'reached your $goalName goal. Keep up the great work!',
      type: NotificationType.savings,
      showDeviceNotification: true,
    );
  }

  static Future<void> checkSavingsDeadlines({
    required String goalName,
    required int daysRemaining,
    required double savedAmount,
    required double targetAmount,
  }) async {
    if (daysRemaining < 0) {
      await saveNotification(
        title: '⚠️ Savings Goal Overdue: $goalName',
        message:
            'Your $goalName goal is ${daysRemaining.abs()} '
            'day${daysRemaining.abs() == 1 ? '' : 's'} overdue. '
            'Saved: ${_fmt(savedAmount)} of ${_fmt(targetAmount)}.',
        type: NotificationType.savings,
        showDeviceNotification: true,
      );
    } else if (daysRemaining <= 3) {
      await saveNotification(
        title: '⏰ Goal Due Very Soon: $goalName',
        message:
            'Only $daysRemaining day${daysRemaining == 1 ? '' : 's'} left '
            'to reach your $goalName goal! '
            'Progress: ${_fmt(savedAmount)} of ${_fmt(targetAmount)}.',
        type: NotificationType.savings,
        showDeviceNotification: true,
      );
    } else if (daysRemaining <= 7) {
      // Guard against division by zero when targetAmount is 0.
      final progressPct = targetAmount > 0
          ? ((savedAmount / targetAmount) * 100).toStringAsFixed(0)
          : '0';
      await saveNotification(
        title: '📅 Savings Deadline Approaching: $goalName',
        message:
            '$daysRemaining days until your $goalName goal deadline. '
            'You\'ve saved ${_fmt(savedAmount)} of ${_fmt(targetAmount)} '
            '($progressPct%).',
        type: NotificationType.savings,
      );
    }
  }

  // ── Streak ────────────────────────────────────────────────────────────────
  static Future<void> notifyStreakMilestone(
      int streakCount, String level) async {
    await saveNotification(
      title: '🔥 Streak Milestone: $streakCount Days!',
      message:
          'Amazing! You\'ve maintained a $streakCount day savings streak '
          'and reached $level level. You\'re building fantastic financial habits!',
      type: NotificationType.streak,
      showDeviceNotification: true,
    );
  }

  static Future<void> checkStreakAtRisk(int streakCount) async {
    if (streakCount <= 0) return;
    await saveNotification(
      title: '⚡ Keep Your Streak Alive!',
      message:
          'Your $streakCount day saving streak is at risk! '
          'Add a savings contribution today to keep the momentum going.',
      type: NotificationType.streak,
      showDeviceNotification: true,
    );
  }

  static Future<void> notifyStreakLost() async {
    await saveNotification(
      title: '💔 Streak Reset',
      message:
          'Your saving streak has been reset due to inactivity. '
          'Don\'t worry — start fresh today and build it back up!',
      type: NotificationType.streak,
    );
  }

  // ── Analysis / Insights ───────────────────────────────────────────────────
  static Future<void> generateWeeklySummary({
    required double weeklyIncome,
    required double weeklyExpenses,
    required double weeklySavings,
  }) async {
    final net = weeklyIncome - weeklyExpenses;
    // Guard against division by zero for savings rate.
    final savingsRate = weeklyIncome > 0
        ? ((weeklySavings / weeklyIncome) * 100).toStringAsFixed(1)
        : '0.0';
    final emoji = net >= 0 ? '📈' : '📉';

    await saveNotification(
      title: '$emoji Weekly Financial Summary',
      message:
          'This week — Income: ${_fmt(weeklyIncome)} · '
          'Expenses: ${_fmt(weeklyExpenses)} · '
          'Savings: ${_fmt(weeklySavings)}. '
          'Savings rate: $savingsRate%. '
          'Net: ${net >= 0 ? '+' : ''}${_fmt(net)}.',
      type: NotificationType.analysis,
    );
  }

  static Future<void> generateMonthlyComparison({
    required double thisMonth,
    required double lastMonth,
  }) async {
    if (lastMonth <= 0) return;
    final change = ((thisMonth - lastMonth) / lastMonth) * 100;
    final isUp = change > 0;
    final emoji = isUp ? '📈' : '📉';

    await saveNotification(
      title: '$emoji Monthly Spending Update',
      message:
          'You spent ${_fmt(thisMonth)} this month vs ${_fmt(lastMonth)} last month '
          '— ${change.abs().toStringAsFixed(1)}% ${isUp ? 'more' : 'less'}. '
          '${isUp ? 'Try to cut back in the coming days.' : 'Great job reducing your spending!'}',
      type: NotificationType.analysis,
    );
  }

  static Future<void> detectUnusualSpending({
    required double todaySpend,
    required double avgDailySpend,
  }) async {
    if (avgDailySpend <= 0) return;
    final ratio = todaySpend / avgDailySpend;
    if (ratio >= 2.5) {
      await saveNotification(
        title: '🔍 Unusual Spending Detected',
        message:
            'Today\'s spending (${_fmt(todaySpend)}) is '
            '${ratio.toStringAsFixed(1)}× your daily average of '
            '${_fmt(avgDailySpend)}. Review your transactions to stay on budget.',
        type: NotificationType.analysis,
        showDeviceNotification: true,
      );
    }
  }

  static Future<void> checkHighFees({
    required double totalFees,
    required double totalExpenses,
  }) async {
    if (totalExpenses <= 0) return;
    final feePct = (totalFees / totalExpenses) * 100;
    if (feePct >= 5) {
      await saveNotification(
        title: '💸 High Transaction Fees Alert',
        message:
            'Transaction fees (${_fmt(totalFees)}) account for '
            '${feePct.toStringAsFixed(1)}% of your total spend this month. '
            'Consider reducing mobile money transfers to save more.',
        type: NotificationType.analysis,
      );
    }
  }

  static Future<void> notifyPositiveSavingsRate(double rate) async {
    if (rate >= 20) {
      await saveNotification(
        title: '⭐ Excellent Savings Rate!',
        message:
            'You\'re saving ${rate.toStringAsFixed(1)}% of your income — '
            'above the recommended 20%! '
            'You\'re on track for strong financial health.',
        type: NotificationType.analysis,
      );
    }
  }

  // ── Reports ───────────────────────────────────────────────────────────────
  static Future<void> notifyReportReady(String period) async {
    await saveNotification(
      title: '📋 Your $period Report is Ready',
      message:
          'Your financial report for $period has been generated. '
          'Tap to view detailed insights on spending, savings, and budget performance.',
      type: NotificationType.report,
    );
  }

  // ── Inactivity ────────────────────────────────────────────────────────────
  static Future<void> checkInactivity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActive = await getLastActive();
    if (lastActive == null) return;

    final daysSince = DateTime.now().difference(lastActive).inDays;

    // Rate-limit: only fire once every 2 days.
    final lastNotifRaw = prefs.getString(_lastInactivityNotifKey);
    if (lastNotifRaw != null) {
      final lastNotif = DateTime.tryParse(lastNotifRaw);
      if (lastNotif != null &&
          DateTime.now().difference(lastNotif).inDays < 2) {
        return;
      }
    }

    String? title;
    String? message;

    if (daysSince >= 7) {
      title = '👋 We Miss You!';
      message =
          'It\'s been $daysSince days since you last checked your finances. '
          'Log in to review your budget and savings goals.';
    } else if (daysSince >= 3) {
      title = '📊 Time to Check Your Finances';
      message =
          'You haven\'t tracked your spending in $daysSince days. '
          'A quick review helps you stay on budget!';
    }

    if (title != null && message != null) {
      await saveNotification(
        title: title,
        message: message,
        type: NotificationType.inactivity,
        showDeviceNotification: true,
      );
      await prefs.setString(
          _lastInactivityNotifKey, DateTime.now().toIso8601String());
    }
  }

  // ── Budget lifecycle ──────────────────────────────────────────────────────
  static Future<void> notifyBudgetCreated(
      String name, double amount) async {
    await saveNotification(
      title: '💼 Budget Created: $name',
      message:
          'New budget "$name" created with ${_fmt(amount)}. '
          'Track your expenses to stay within limits.',
      type: NotificationType.budget,
    );
  }

  static Future<void> notifyBudgetFinalized(
      String name, double spent, double total) async {
    final remaining = total - spent;
    final underBudget = remaining >= 0;
    await saveNotification(
      title: '✅ Budget Finalized: $name',
      message: underBudget
          ? 'Great job! You finalized "$name" with ${_fmt(remaining)} '
              'to spare out of ${_fmt(total)}.'
          : 'Budget "$name" finalized. You overspent by '
              '${_fmt(remaining.abs())} over the ${_fmt(total)} limit.',
      type: NotificationType.budget,
    );
  }

  // ── Private helper ────────────────────────────────────────────────────────
  /// Formats a double as a compact Ksh string (e.g. Ksh 1.2K, Ksh 3.4M).
  /// Uses v.abs() for magnitude so negative values bucket correctly.
  static String _fmt(double v) {
    final magnitude = v.abs();
    if (magnitude >= 1000000) {
      return 'Ksh ${(v / 1000000).toStringAsFixed(1)}M';
    } else if (magnitude >= 1000) {
      return 'Ksh ${(v / 1000).toStringAsFixed(1)}K';
    }
    return 'Ksh ${v.round()}';
  }
}