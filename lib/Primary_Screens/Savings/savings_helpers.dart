import 'dart:convert';

import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── SharedPreferences keys ───────────────────────────────────────────────────
const keySavings = 'savings';
const keyTransactions = 'transactions';
const keyTotalIncome = 'total_income';
const keyStreakCount = 'streak_count';
const keyLastSaveDate = 'last_save_date';
const keyStreakLevel = 'streak_level';

// ─── Currency formatter ───────────────────────────────────────────────────────
class SavingsFmt {
  static final _f = NumberFormat('#,##0', 'en_US');
  static String ksh(double v) => 'Ksh ${_f.format(v.round())}';
}

// ─── Streak helpers ───────────────────────────────────────────────────────────
String streakLevelFor(int n) {
  if (n == 0) return 'Base';
  if (n < 7) return 'Bronze';
  if (n < 30) return 'Silver';
  if (n < 90) return 'Gold';
  if (n < 180) return 'Platinum';
  return 'Diamond';
}

Future<void> checkStreakExpiry(
  SharedPreferences prefs, {
  required void Function(int count, String level) onReset,
  required Future<void> Function(String title, String body) notify,
}) async {
  final lastStr = prefs.getString(keyLastSaveDate) ?? '';
  if (lastStr.isEmpty) return;
  final diff = DateTime.now()
      .difference(DateFormat('yyyy-MM-dd').parse(lastStr))
      .inDays;
  if (diff >= 3) {
    await prefs.setInt(keyStreakCount, 0);
    await prefs.setString(keyStreakLevel, 'Base');
    onReset(0, 'Base');
    await notify(
      '💔 Streak Lost',
      'Streak reset due to inactivity. Start saving again!',
    );
  }
}

Future<({int count, String level})> updateStreak(
  int currentStreakCount,
) async {
  final prefs = await SharedPreferences.getInstance();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final last = prefs.getString(keyLastSaveDate) ?? '';
  if (last == today) return (count: currentStreakCount, level: streakLevelFor(currentStreakCount));

  int newCount;
  if (last.isNotEmpty) {
    final diff = DateTime.now()
        .difference(DateFormat('yyyy-MM-dd').parse(last))
        .inDays;
    newCount = diff == 1 ? currentStreakCount + 1 : 1;
  } else {
    newCount = 1;
  }
  final newLevel = streakLevelFor(newCount);
  await prefs.setInt(keyStreakCount, newCount);
  await prefs.setString(keyStreakLevel, newLevel);
  await prefs.setString(keyLastSaveDate, today);
  return (count: newCount, level: newLevel);
}

// ─── Notification helper ──────────────────────────────────────────────────────
Future<void> savingsNotify(
  String title,
  String body, {
  NotificationType type = NotificationType.savings,
}) async {
  await LocalNotificationStore.saveNotification(
    title: title,
    message: body,
    type: type,
  );
}

// ─── Global transaction logger ────────────────────────────────────────────────
Future<void> logGlobalTransaction(
  String title,
  double amount,
  String type, {
  double transactionCost = 0.0,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(keyTransactions) ?? '[]';
  final list = List<Map<String, dynamic>>.from(json.decode(raw));
  list.insert(0, {
    'title': title,
    'amount': amount,
    'transactionCost': transactionCost,
    'type': type,
    'date': DateTime.now().toIso8601String(),
  });
  await prefs.setString(keyTransactions, json.encode(list));
}
