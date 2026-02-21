import 'dart:convert';

import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_data_models.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_keys.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Smart Notification Service ───────────────────────────────────────────────
/// Generates and persists contextual, intelligent notifications.
///
/// Call [SmartNotificationService.runAllChecks] on app open / home page resume.
/// All results are written to [LocalNotificationStore] — zero network required.
class SmartNotificationService {
  // ── Core send helper ────────────────────────────────────────────────────────
  /// Convenience wrapper to save a notification to [LocalNotificationStore].
  static Future<void> send({
    required String title,
    required String message,
    required NotificationType type,
    String? dedupKey,
  }) async {
    await LocalNotificationStore.saveNotification(
      title: title,
      message: message,
      type: type,
      dedupKey: dedupKey,
    );
  }

  // ── Master check runner ─────────────────────────────────────────────────────
  /// Run all smart notification checks.
  /// Call this every time the app opens (e.g., in [HomePage.initState]).
  static Future<void> runAllChecks() async {
    final prefs = await SharedPreferences.getInstance();

    // Update last-open timestamp (used by inactivity check)
    final todayKey = _dateKey(DateTime.now());
    await prefs.setString(NotificationKeys.lastAppOpen, todayKey);

    final txList = List<Map<String, dynamic>>.from(
      json.decode(prefs.getString(NotificationKeys.transactions) ?? '[]'),
    );
    final budgetList = (prefs.getStringList(NotificationKeys.budgets) ?? [])
        .map((s) => BudgetData.fromMap(json.decode(s)))
        .toList();
    final savingsList = (prefs.getStringList(NotificationKeys.savings) ?? [])
        .map((s) => SavingData.fromMap(json.decode(s)))
        .toList();
    final totalIncome = prefs.getDouble(NotificationKeys.totalIncome) ?? 0.0;

    // Run all checks in parallel for performance
    await Future.wait([
      _checkBudgetAlerts(prefs, budgetList),
      _checkSavingsGoalDue(prefs, savingsList),
      _checkWeeklySummary(prefs, txList, totalIncome),
      _checkMonthlySummary(prefs, txList, totalIncome),
      _checkUnusualSpending(prefs, txList),
      _checkStreakReminder(prefs),
      _checkSpendingInsights(prefs, txList, totalIncome),
      _checkInactivity(prefs),
    ]);
  }

  // ── Budget Near Limit (80%) & Overspent Alerts ─────────────────────────────
  static Future<void> _checkBudgetAlerts(
    SharedPreferences prefs,
    List<BudgetData> budgets,
  ) async {
    final flagsRaw = prefs.getString(NotificationKeys.budgetAlerts) ?? '{}';
    final flags = Map<String, dynamic>.from(json.decode(flagsRaw));
    bool changed = false;

    for (final budget in budgets) {
      if (budget.total <= 0) continue;
      final pct = budget.totalSpent / budget.total;
      final key = budget.id;

      // 80% warning — fire once per budget
      if (pct >= 0.8 && pct < 1.0 && flags[key] != '80') {
        await send(
          title: 'Budget Alert: ${budget.name}',
          message:
              'You\'ve used ${(pct * 100).toStringAsFixed(0)}% of your '
              '"${budget.name}" budget. Only Ksh ${_fmt(budget.total - budget.totalSpent)} remaining.',
          type: NotificationType.budget,
        );
        flags[key] = '80';
        changed = true;
      }

      // Overspent — fire once per budget
      if (pct >= 1.0 && flags[key] != 'over') {
        await send(
          title: 'Budget Exceeded: ${budget.name}',
          message:
              'You\'ve overspent your "${budget.name}" budget by '
              'Ksh ${_fmt(budget.totalSpent - budget.total)}. Consider reviewing your spending.',
          type: NotificationType.budget,
        );
        flags[key] = 'over';
        changed = true;
      }

      // Reset flag if usage dropped back below 80%
      if (pct < 0.8 && flags.containsKey(key)) {
        flags.remove(key);
        changed = true;
      }
    }

    if (changed) {
      await prefs.setString(NotificationKeys.budgetAlerts, json.encode(flags));
    }
  }

  // ── Savings Goal Due Reminders ──────────────────────────────────────────────
  static Future<void> _checkSavingsGoalDue(
    SharedPreferences prefs,
    List<SavingData> savings,
  ) async {
    final alertedRaw =
        prefs.getString(NotificationKeys.savingsDueAlerts) ?? '[]';
    final alerted = List<String>.from(json.decode(alertedRaw));
    bool changed = false;

    for (final goal in savings) {
      if (goal.achieved) continue;
      final daysLeft = goal.deadline.difference(DateTime.now()).inDays;

      // 7-day reminder
      final alertKey = '${goal.name}_due';
      if (daysLeft <= 7 && daysLeft > 1 && !alerted.contains(alertKey)) {
        await send(
          title: 'Savings Goal Due Soon: ${goal.name}',
          message:
              '"${goal.name}" is due in $daysLeft day${daysLeft == 1 ? '' : 's'}. '
              'You\'ve saved Ksh ${_fmt(goal.savedAmount)} of Ksh ${_fmt(goal.targetAmount)} '
              '(${(goal.progressPercent * 100).toStringAsFixed(0)}%). Keep it up!',
          type: NotificationType.savings,
        );
        alerted.add(alertKey);
        changed = true;
      }

      // 1-day urgent reminder
      final urgentKey = '${goal.name}_urgent';
      if (daysLeft == 1 && !alerted.contains(urgentKey)) {
        await send(
          title: 'Last Day — Savings Goal: ${goal.name}',
          message:
              'Your "${goal.name}" goal deadline is tomorrow! '
              'Ksh ${_fmt((goal.targetAmount - goal.savedAmount).clamp(0, double.infinity))} still needed.',
          type: NotificationType.savings,
        );
        alerted.add(urgentKey);
        changed = true;
      }

      // Overdue (fire for the first day past deadline only)
      final overdueKey = '${goal.name}_overdue';
      if (daysLeft < 0 && daysLeft >= -1 && !alerted.contains(overdueKey)) {
        await send(
          title: 'Goal Overdue: ${goal.name}',
          message:
              'Your savings goal "${goal.name}" has passed its deadline. '
              'You reached ${(goal.progressPercent * 100).toStringAsFixed(0)}% — '
              'consider extending the deadline.',
          type: NotificationType.savings,
        );
        alerted.add(overdueKey);
        changed = true;
      }

      // Reset due alerts if goal was extended / edited back
      if (daysLeft > 7) {
        alerted.removeWhere((k) => k.startsWith('${goal.name}_'));
        changed = true;
      }
    }

    if (changed) {
      await prefs.setString(
          NotificationKeys.savingsDueAlerts, json.encode(alerted));
    }
  }

  // ── Weekly Financial Summary (Mondays) ─────────────────────────────────────
  static Future<void> _checkWeeklySummary(
    SharedPreferences prefs,
    List<Map<String, dynamic>> txList,
    double totalIncome,
  ) async {
    final now = DateTime.now();
    if (now.weekday != DateTime.monday) return;

    final thisWeekKey = '${now.year}-W${_weekNumber(now)}';
    if (prefs.getString(NotificationKeys.lastWeeklySummaryDate) ==
        thisWeekKey) return;

    final weekStart = now.subtract(const Duration(days: 7));
    double income = 0, expenses = 0, savings = 0;

    for (final tx in txList) {
      final d = DateTime.parse(tx['date']);
      if (d.isBefore(weekStart)) continue;
      final amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final fee =
          double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
      if (tx['type'] == 'income') {
        income += amt;
      } else if (tx['type'] == 'savings_deduction' ||
          tx['type'] == 'saving_deposit') {
        savings += amt;
        expenses += amt + fee;
      } else {
        expenses += amt + fee;
      }
    }

    if (income == 0 && expenses == 0) return;

    final net = income - expenses;
    final dir = net >= 0 ? 'Positive' : 'Negative';
    final savingsRate = income > 0 ? (savings / income * 100) : 0.0;

    await send(
      title: '$dir Weekly Financial Summary',
      message:
          'Last 7 days — Income: Ksh ${_fmt(income)} | Expenses: Ksh ${_fmt(expenses)} | '
          'Net: ${net >= 0 ? '+' : ''}Ksh ${_fmt(net)}. '
          'Savings rate: ${savingsRate.toStringAsFixed(1)}%.',
      type: NotificationType.report,
    );

    await prefs.setString(NotificationKeys.lastWeeklySummaryDate, thisWeekKey);
  }

  // ── Monthly Financial Summary (1st of month) ────────────────────────────────
  static Future<void> _checkMonthlySummary(
    SharedPreferences prefs,
    List<Map<String, dynamic>> txList,
    double totalIncome,
  ) async {
    final now = DateTime.now();
    if (now.day != 1) return;

    final thisMonthKey = '${now.year}-${now.month}';
    if (prefs.getString(NotificationKeys.lastMonthlySummaryDate) ==
        thisMonthKey) return;

    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final prevMonthStart = DateTime(prevYear, prevMonth, 1);
    final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    double income = 0, expenses = 0, savings = 0;
    int txCount = 0;

    for (final tx in txList) {
      final d = DateTime.parse(tx['date']);
      if (d.isBefore(prevMonthStart) || d.isAfter(prevMonthEnd)) continue;
      final amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final fee =
          double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
      txCount++;
      if (tx['type'] == 'income') {
        income += amt;
      } else if (tx['type'] == 'savings_deduction' ||
          tx['type'] == 'saving_deposit') {
        savings += amt;
        expenses += amt + fee;
      } else {
        expenses += amt + fee;
      }
    }

    if (txCount == 0) return;

    final net = income - expenses;
    final savingsRate = income > 0 ? (savings / income * 100) : 0.0;
    final monthName = _monthName(prevMonth);

    await send(
      title: '$monthName Monthly Summary',
      message:
          'Income: Ksh ${_fmt(income)} | Expenses: Ksh ${_fmt(expenses)} | '
          'Saved: Ksh ${_fmt(savings)} | Net: ${net >= 0 ? '+' : ''}Ksh ${_fmt(net)}. '
          'Savings rate: ${savingsRate.toStringAsFixed(1)}% across $txCount transactions.',
      type: NotificationType.report,
    );

    await prefs.setString(
        NotificationKeys.lastMonthlySummaryDate, thisMonthKey);
  }

  // ── Unusual Spending Detection (>2.5× daily average) ───────────────────────
  static Future<void> _checkUnusualSpending(
    SharedPreferences prefs,
    List<Map<String, dynamic>> txList,
  ) async {
    final today = _dateKey(DateTime.now());
    if (prefs.getString(NotificationKeys.unusualSpendingAlert) == today) return;

    final now = DateTime.now();
    double todaySpend = 0;
    for (final tx in txList) {
      if (tx['type'] == 'income') continue;
      final d = DateTime.parse(tx['date']);
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        final amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
        final fee =
            double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
        todaySpend += amt + fee;
      }
    }

    // Build daily totals for the past 30 days (excluding today)
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final dailyMap = <String, double>{};
    for (final tx in txList) {
      if (tx['type'] == 'income') continue;
      final d = DateTime.parse(tx['date']);
      if (d.isBefore(thirtyDaysAgo)) continue;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        continue;
      }
      final key = _dateKey(d);
      final amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final fee =
          double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
      dailyMap[key] = (dailyMap[key] ?? 0) + amt + fee;
    }

    if (dailyMap.length < 5) return; // Not enough history
    final avgDaily =
        dailyMap.values.fold(0.0, (a, b) => a + b) / dailyMap.length;
    if (avgDaily <= 0) return;

    if (todaySpend > avgDaily * 2.5) {
      await send(
        title: 'Unusual Spending Detected',
        message:
            'You\'ve spent Ksh ${_fmt(todaySpend)} today — '
            '${(todaySpend / avgDaily).toStringAsFixed(1)}× your daily average '
            'of Ksh ${_fmt(avgDaily)}. Everything okay?',
        type: NotificationType.insight,
      );
      await prefs.setString(NotificationKeys.unusualSpendingAlert, today);
    }
  }

  // ── Streak Reminder (2 days without saving) ─────────────────────────────────
  static Future<void> _checkStreakReminder(SharedPreferences prefs) async {
    final lastSaveDate =
        prefs.getString(NotificationKeys.lastSaveDate) ?? '';
    if (lastSaveDate.isEmpty) return;

    final today = _dateKey(DateTime.now());
    if (prefs.getString(NotificationKeys.streakReminderDate) == today) return;

    final lastSave = DateTime.parse(lastSaveDate);
    final daysSince = DateTime.now().difference(lastSave).inDays;
    final streakCount = prefs.getInt(NotificationKeys.streakCount) ?? 0;

    if (daysSince == 2 && streakCount > 0) {
      await send(
        title: 'Don\'t Break Your Streak!',
        message:
            'You have a $streakCount-day savings streak! '
            'Add funds to a savings goal today to keep it alive.',
        type: NotificationType.streak,
      );
      await prefs.setString(NotificationKeys.streakReminderDate, today);
    }
  }

  // ── Spending Insights (weekly comparison — Sundays) ─────────────────────────
  static Future<void> _checkSpendingInsights(
    SharedPreferences prefs,
    List<Map<String, dynamic>> txList,
    double totalIncome,
  ) async {
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return;

    final thisWeekKey = '${now.year}-W${_weekNumber(now)}-insight';
    if (prefs.getString(NotificationKeys.lastAnalysisDate) == thisWeekKey)
      return;

    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(
      now.month == 1 ? now.year - 1 : now.year,
      now.month == 1 ? 12 : now.month - 1,
      1,
    );
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    double thisMonthExp = 0, lastMonthExp = 0;
    double thisMonthSavings = 0, lastMonthSavings = 0;

    for (final tx in txList) {
      if (tx['type'] == 'income') continue;
      final d = DateTime.parse(tx['date']);
      final amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final fee =
          double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
      final isSavings = tx['type'] == 'savings_deduction' ||
          tx['type'] == 'saving_deposit';

      if (d.isAfter(thisMonthStart)) {
        thisMonthExp += amt + fee;
        if (isSavings) thisMonthSavings += amt;
      } else if (d.isAfter(lastMonthStart) && d.isBefore(lastMonthEnd)) {
        lastMonthExp += amt + fee;
        if (isSavings) lastMonthSavings += amt;
      }
    }

    if (lastMonthExp <= 0) return;

    final changeAmt = thisMonthExp - lastMonthExp;
    final changePct = (changeAmt / lastMonthExp) * 100;

    if (changePct <= -10) {
      await send(
        title:
            'Great Progress! Spending Down ${changePct.abs().toStringAsFixed(1)}%',
        message:
            'You\'ve spent Ksh ${_fmt(thisMonthExp)} this month vs '
            'Ksh ${_fmt(lastMonthExp)} last month. '
            'That\'s Ksh ${_fmt(changeAmt.abs())} saved in reduced spending!',
        type: NotificationType.insight,
      );
    } else if (changePct >= 20) {
      await send(
        title: 'Spending Up ${changePct.toStringAsFixed(1)}% This Month',
        message:
            'Your spending is Ksh ${_fmt(changeAmt)} higher than last month. '
            'Review your transactions to identify areas to cut back.',
        type: NotificationType.analysis,
      );
    }

    // Savings improvement
    if (lastMonthSavings > 0 && thisMonthSavings > lastMonthSavings) {
      final savingsPct =
          ((thisMonthSavings - lastMonthSavings) / lastMonthSavings) * 100;
      if (savingsPct >= 15) {
        await send(
          title: 'You Saved ${savingsPct.toStringAsFixed(0)}% More This Month!',
          message:
              'Ksh ${_fmt(thisMonthSavings)} saved this month vs '
              'Ksh ${_fmt(lastMonthSavings)} last month. '
              'Your financial discipline is paying off!',
          type: NotificationType.insight,
        );
      }
    }

    await prefs.setString(NotificationKeys.lastAnalysisDate, thisWeekKey);
  }

  // ── Inactivity Reminder (7+ days without opening app) ──────────────────────
  static Future<void> _checkInactivity(SharedPreferences prefs) async {
    final lastOpenStr = prefs.getString(NotificationKeys.lastAppOpen) ?? '';
    if (lastOpenStr.isEmpty) return;

    // This check runs *after* updating last_app_open, so we compare against
    // the value that was saved last session (before today's update). However
    // since we overwrite it above before calling this, we use the previous raw
    // storage value by checking days between the stored datetime and now.
    // We track a separate inactivity alert date so it fires only once per week.
    final today = _dateKey(DateTime.now());
    if (prefs.getString(NotificationKeys.inactivityAlertDate) == today) return;

    try {
      final lastOpen = DateTime.parse(lastOpenStr);
      final daysSince = DateTime.now().difference(lastOpen).inDays;

      if (daysSince >= 7) {
        await send(
          title: 'We Miss You!',
          message:
              'You haven\'t checked your finances in $daysSince days. '
              'Stay on top of your money — open the app and review your spending!',
          type: NotificationType.system,
        );
        await prefs.setString(NotificationKeys.inactivityAlertDate, today);
      }
    } catch (_) {}
  }

  // ── Utility helpers ─────────────────────────────────────────────────────────
  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.round().toString();
  }

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  static int _weekNumber(DateTime d) {
    final firstDayOfYear = DateTime(d.year, 1, 1);
    return ((d.difference(firstDayOfYear).inDays + firstDayOfYear.weekday) / 7)
        .ceil();
  }

  static String _monthName(int m) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return m >= 1 && m <= 12 ? names[m] : '';
  }
}
