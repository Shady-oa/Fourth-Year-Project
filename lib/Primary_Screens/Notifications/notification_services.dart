import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Notification Types ───────────────────────────────────────────────────────
enum NotificationType {
  budget,
  savings,
  streak,
  analysis,
  report,
  insight,
  system,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
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
      case NotificationType.insight:
        return 'insight';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromString(String? value) {
    switch (value) {
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
      case 'insight':
        return NotificationType.insight;
      default:
        return NotificationType.system;
    }
  }
}

// ─── Keys for SharedPreferences ───────────────────────────────────────────────
class _Keys {
  static const transactions = 'transactions';
  static const budgets = 'budgets';
  static const savings = 'savings';
  static const totalIncome = 'total_income';
  static const streakCount = 'streak_count';
  static const lastSaveDate = 'last_save_date';

  // Tracking keys to avoid duplicate notifications
  static const lastWeeklySummaryDate = 'last_weekly_summary_date';
  static const lastMonthlySummaryDate = 'last_monthly_summary_date';
  static const lastAnalysisDate = 'last_analysis_date';
  static const budgetAlerts = 'budget_alert_flags'; // JSON map of budgetId -> alertLevel
  static const savingsDueAlerts = 'savings_due_alerts'; // JSON list of goal names alerted
  static const unusualSpendingAlert = 'unusual_spending_alert_date';
  static const streakReminderDate = 'streak_reminder_date';
}

// ─── Smart Notification Service ───────────────────────────────────────────────
/// Central service for generating intelligent, context-aware notifications.
/// Call [SmartNotificationService.runAllChecks] periodically (e.g., on app open).
class SmartNotificationService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static String? get _uid => _auth.currentUser?.uid;

  // ── Core send method ────────────────────────────────────────────────────────
  static Future<void> send({
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'type': type.value,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      // Silently fail — notifications are non-critical
    }
  }

  // ── Master check runner ─────────────────────────────────────────────────────
  /// Run all smart notification checks. Call this on app open / page resume.
  static Future<void> runAllChecks() async {
    final uid = _uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    final txList = List<Map<String, dynamic>>.from(
      json.decode(prefs.getString(_Keys.transactions) ?? '[]'),
    );
    final budgetList = (prefs.getStringList(_Keys.budgets) ?? [])
        .map((s) => _BudgetData.fromMap(json.decode(s)))
        .toList();
    final savingsList = (prefs.getStringList(_Keys.savings) ?? [])
        .map((s) => _SavingData.fromMap(json.decode(s)))
        .toList();
    final totalIncome = prefs.getDouble(_Keys.totalIncome) ?? 0.0;

    // Run checks in parallel for performance
    await Future.wait([
      _checkBudgetAlerts(prefs, budgetList),
      _checkSavingsGoalDue(prefs, savingsList),
      _checkWeeklySummary(prefs, txList, totalIncome),
      _checkMonthlySummary(prefs, txList, totalIncome),
      _checkUnusualSpending(prefs, txList),
      _checkStreakReminder(prefs),
      _checkSpendingInsights(prefs, txList, totalIncome),
    ]);
  }

  // ── Budget Near Limit (80% threshold) ──────────────────────────────────────
  static Future<void> _checkBudgetAlerts(
    SharedPreferences prefs,
    List<_BudgetData> budgets,
  ) async {
    final flagsRaw = prefs.getString(_Keys.budgetAlerts) ?? '{}';
    final flags = Map<String, dynamic>.from(json.decode(flagsRaw));
    bool changed = false;

    for (final budget in budgets) {
      if (budget.total <= 0) continue;
      final pct = budget.totalSpent / budget.total;
      final key = budget.id;

      // 80% warning — alert once per budget
      if (pct >= 0.8 && pct < 1.0 && flags[key] != '80') {
        await send(
          title: '⚠️ Budget Alert: ${budget.name}',
          message:
              'You\'ve used ${(pct * 100).toStringAsFixed(0)}% of your "${budget.name}" budget. '
              'Only Ksh ${_fmt(budget.total - budget.totalSpent)} remaining.',
          type: NotificationType.budget,
        );
        flags[key] = '80';
        changed = true;
      }

      // Overspent — alert once per budget
      if (pct >= 1.0 && flags[key] != 'over') {
        await send(
          title: '🚨 Budget Exceeded: ${budget.name}',
          message:
              'You\'ve overspent your "${budget.name}" budget by Ksh ${_fmt(budget.totalSpent - budget.total)}. '
              'Consider reviewing your spending.',
          type: NotificationType.budget,
        );
        flags[key] = 'over';
        changed = true;
      }

      // Reset flag if budget was edited and usage dropped below 80%
      if (pct < 0.8 && flags.containsKey(key)) {
        flags.remove(key);
        changed = true;
      }
    }

    if (changed) {
      await prefs.setString(_Keys.budgetAlerts, json.encode(flags));
    }
  }

  // ── Savings Goal Due Reminders ──────────────────────────────────────────────
  static Future<void> _checkSavingsGoalDue(
    SharedPreferences prefs,
    List<_SavingData> savings,
  ) async {
    final alertedRaw = prefs.getString(_Keys.savingsDueAlerts) ?? '[]';
    final alerted = List<String>.from(json.decode(alertedRaw));
    bool changed = false;

    for (final goal in savings) {
      if (goal.achieved) continue;
      final daysLeft = goal.deadline.difference(DateTime.now()).inDays;
      final alertKey = '${goal.name}_due';

      // 7-day reminder
      if (daysLeft <= 7 && daysLeft > 0 && !alerted.contains(alertKey)) {
        await send(
          title: '⏰ Savings Goal Due Soon: ${goal.name}',
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
          title: '🚨 Last Day! Savings Goal: ${goal.name}',
          message:
              'Your "${goal.name}" goal deadline is tomorrow! '
              'Ksh ${_fmt((goal.targetAmount - goal.savedAmount).clamp(0, double.infinity))} still needed.',
          type: NotificationType.savings,
        );
        alerted.add(urgentKey);
        changed = true;
      }

      // Overdue
      if (daysLeft < 0 && daysLeft >= -1 && !alerted.contains('${goal.name}_overdue')) {
        await send(
          title: '📅 Goal Overdue: ${goal.name}',
          message:
              'Your savings goal "${goal.name}" has passed its deadline. '
              'You reached ${(goal.progressPercent * 100).toStringAsFixed(0)}% — consider extending the deadline.',
          type: NotificationType.savings,
        );
        alerted.add('${goal.name}_overdue');
        changed = true;
      }

      // Reset due alerts when goal is reset/edited
      if (daysLeft > 7) {
        alerted.removeWhere((k) => k.startsWith('${goal.name}_'));
        changed = true;
      }
    }

    if (changed) {
      await prefs.setString(_Keys.savingsDueAlerts, json.encode(alerted));
    }
  }

  // ── Weekly Summary ──────────────────────────────────────────────────────────
  static Future<void> _checkWeeklySummary(
    SharedPreferences prefs,
    List<Map<String, dynamic>> txList,
    double totalIncome,
  ) async {
    final lastStr = prefs.getString(_Keys.lastWeeklySummaryDate) ?? '';
    final now = DateTime.now();

    // Only send on Mondays and if not sent this week
    if (now.weekday != DateTime.monday) return;
    final thisMonday = '${now.year}-W${_weekNumber(now)}';
    if (lastStr == thisMonday) return;

    // Calculate last 7 days stats
    final weekStart = now.subtract(const Duration(days: 7));
    double income = 0, expenses = 0, savings = 0;
    for (final tx in txList) {
      final d = DateTime.parse(tx['date']);
      if (d.isBefore(weekStart)) continue;
      final amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final fee = double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
      if (tx['type'] == 'income') {
        income += amt;
      } else if (tx['type'] == 'savings_deduction' || tx['type'] == 'saving_deposit') {
        savings += amt;
        expenses += amt + fee;
      } else {
        expenses += amt + fee;
      }
    }

    if (income == 0 && expenses == 0) return; // No activity, skip

    final net = income - expenses;
    final emoji = net >= 0 ? '📈' : '📉';
    final savingsRate = income > 0 ? (savings / income * 100) : 0.0;

    await send(
      title: '$emoji Weekly Financial Summary',
      message:
          'Last 7 days: Income Ksh ${_fmt(income)} | Expenses Ksh ${_fmt(expenses)} | '
          'Net ${net >= 0 ? '+' : ''}Ksh ${_fmt(net)}. '
          'Savings rate: ${savingsRate.toStringAsFixed(1)}%.',
      type: NotificationType.report,
    );

    await prefs.setString(_Keys.lastWeeklySummaryDate, thisMonday);
  }

  // ── Monthly Summary ─────────────────────────────────────────────────────────
  static Future<void> _checkMonthlySummary(
    SharedPreferences prefs,
    List<Map<String, dynamic>> txList,
    double totalIncome,
  ) async {
    final now = DateTime.now();
    // Only on 1st of month
    if (now.day != 1) return;

    final lastStr = prefs.getString(_Keys.lastMonthlySummaryDate) ?? '';
    final thisMonth = '${now.year}-${now.month}';
    if (lastStr == thisMonth) return;

    // Previous month stats
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    final prevMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
    double income = 0, expenses = 0, savings = 0;
    int txCount = 0;

    for (final tx in txList) {
      final d = DateTime.parse(tx['date']);
      if (d.isBefore(prevMonthStart) || d.isAfter(prevMonthEnd)) continue;
      final amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final fee = double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
      txCount++;
      if (tx['type'] == 'income') {
        income += amt;
      } else if (tx['type'] == 'savings_deduction' || tx['type'] == 'saving_deposit') {
        savings += amt;
        expenses += amt + fee;
      } else {
        expenses += amt + fee;
      }
    }

    if (txCount == 0) return;

    final net = income - expenses;
    final savingsRate = income > 0 ? (savings / income * 100) : 0.0;
    final monthName = _monthName(now.month - 1 == 0 ? 12 : now.month - 1);

    await send(
      title: '📊 $monthName Monthly Summary',
      message:
          'Income: Ksh ${_fmt(income)} | Expenses: Ksh ${_fmt(expenses)} | '
          'Saved: Ksh ${_fmt(savings)} | Net: ${net >= 0 ? '+' : ''}Ksh ${_fmt(net)}. '
          'Savings rate: ${savingsRate.toStringAsFixed(1)}% across $txCount transactions.',
      type: NotificationType.report,
    );

    await prefs.setString(_Keys.lastMonthlySummaryDate, thisMonth);
  }

  // ── Unusual Spending Detection ──────────────────────────────────────────────
  static Future<void> _checkUnusualSpending(
    SharedPreferences prefs,
    List<Map<String, dynamic>> txList,
  ) async {
    final lastStr = prefs.getString(_Keys.unusualSpendingAlert) ?? '';
    final today = _dateKey(DateTime.now());
    if (lastStr == today) return; // Check once per day

    final now = DateTime.now();
    // Today's spending
    double todaySpend = 0;
    for (final tx in txList) {
      final d = DateTime.parse(tx['date']);
      if (tx['type'] == 'income') continue;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        final amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
        final fee = double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
        todaySpend += amt + fee;
      }
    }

    // Average daily spending over last 30 days (excluding today)
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    double totalPast = 0;
    int dayCount = 0;
    final dailyMap = <String, double>{};
    for (final tx in txList) {
      final d = DateTime.parse(tx['date']);
      if (tx['type'] == 'income') continue;
      if (d.isBefore(thirtyDaysAgo)) continue;
      if (d.year == now.year && d.month == now.month && d.day == now.day) continue;
      final key = _dateKey(d);
      final amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final fee = double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
      dailyMap[key] = (dailyMap[key] ?? 0) + amt + fee;
    }
    for (final v in dailyMap.values) {
      totalPast += v;
      dayCount++;
    }

    if (dayCount < 5) return; // Not enough data
    final avgDaily = totalPast / dayCount;
    if (avgDaily <= 0) return;

    // Flag if today's spend is >2.5x average
    if (todaySpend > avgDaily * 2.5) {
      await send(
        title: '🔍 Unusual Spending Detected',
        message:
            'You\'ve spent Ksh ${_fmt(todaySpend)} today, which is ${(todaySpend / avgDaily).toStringAsFixed(1)}x '
            'your daily average of Ksh ${_fmt(avgDaily)}. Everything okay?',
        type: NotificationType.insight,
      );
      await prefs.setString(_Keys.unusualSpendingAlert, today);
    }
  }

  // ── Streak Reminder ─────────────────────────────────────────────────────────
  static Future<void> _checkStreakReminder(SharedPreferences prefs) async {
    final lastSaveDate = prefs.getString(_Keys.lastSaveDate) ?? '';
    if (lastSaveDate.isEmpty) return;

    final lastStr = prefs.getString(_Keys.streakReminderDate) ?? '';
    final today = _dateKey(DateTime.now());
    if (lastStr == today) return;

    final lastSave = DateTime.parse(lastSaveDate);
    final daysSince = DateTime.now().difference(lastSave).inDays;
    final streakCount = prefs.getInt(_Keys.streakCount) ?? 0;

    // Remind if 2 days without saving and has an active streak
    if (daysSince == 2 && streakCount > 0) {
      await send(
        title: '🔥 Don\'t Break Your Streak!',
        message:
            'You have a $streakCount-day savings streak! Add funds to a savings goal today to keep it alive.',
        type: NotificationType.streak,
      );
      await prefs.setString(_Keys.streakReminderDate, today);
    }
  }

  // ── Spending Insight ─────────────────────────────────────────────────────────
  static Future<void> _checkSpendingInsights(
    SharedPreferences prefs,
    List<Map<String, dynamic>> txList,
    double totalIncome,
  ) async {
    final lastStr = prefs.getString(_Keys.lastAnalysisDate) ?? '';
    final now = DateTime.now();
    // Run insight check weekly on Sundays
    if (now.weekday != DateTime.sunday) return;
    final thisWeek = '${now.year}-W${_weekNumber(now)}-insight';
    if (lastStr == thisWeek) return;

    // Compare this month vs last month expenses
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    double thisMonthExp = 0, lastMonthExp = 0;
    double thisMonthSavings = 0, lastMonthSavings = 0;

    for (final tx in txList) {
      if (tx['type'] == 'income') continue;
      final d = DateTime.parse(tx['date']);
      final amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final fee = double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
      final isSavings = tx['type'] == 'savings_deduction' || tx['type'] == 'saving_deposit';

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
      // Spending down significantly
      await send(
        title: '🎉 Great Progress! Spending Down ${changePct.abs().toStringAsFixed(1)}%',
        message:
            'You\'ve spent Ksh ${_fmt(thisMonthExp)} this month vs Ksh ${_fmt(lastMonthExp)} last month. '
            'That\'s Ksh ${_fmt(changeAmt.abs())} saved in reduced spending!',
        type: NotificationType.insight,
      );
    } else if (changePct >= 20) {
      // Spending up significantly
      await send(
        title: '📊 Spending Increased ${changePct.toStringAsFixed(1)}% This Month',
        message:
            'Your spending is Ksh ${_fmt(changeAmt)} higher than last month. '
            'Review your transactions to identify areas to cut back.',
        type: NotificationType.analysis,
      );
    }

    // Savings improvement insight
    if (lastMonthSavings > 0 && thisMonthSavings > lastMonthSavings) {
      final savingsPct = ((thisMonthSavings - lastMonthSavings) / lastMonthSavings) * 100;
      if (savingsPct >= 15) {
        await send(
          title: '💰 You Saved ${savingsPct.toStringAsFixed(0)}% More This Month!',
          message:
              'Ksh ${_fmt(thisMonthSavings)} saved this month vs Ksh ${_fmt(lastMonthSavings)} last month. '
              'Your financial discipline is paying off! 🌟',
          type: NotificationType.insight,
        );
      }
    }

    await prefs.setString(_Keys.lastAnalysisDate, thisWeek);
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
    return ((d.difference(firstDayOfYear).inDays + firstDayOfYear.weekday) / 7).ceil();
  }

  static String _monthName(int m) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return m >= 1 && m <= 12 ? names[m] : '';
  }
}

// ─── Lightweight local data models for the service ───────────────────────────
class _BudgetData {
  final String id;
  final String name;
  final double total;
  final double totalSpent;
  final bool isChecked;

  _BudgetData({
    required this.id,
    required this.name,
    required this.total,
    required this.totalSpent,
    required this.isChecked,
  });

  factory _BudgetData.fromMap(Map<String, dynamic> map) {
    final expenses = (map['expenses'] as List? ?? []);
    final spent = expenses.fold<double>(
      0.0,
      (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0.0),
    );
    return _BudgetData(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      totalSpent: spent,
      isChecked: map['isChecked'] ?? false,
    );
  }
}

class _SavingData {
  final String name;
  final double savedAmount;
  final double targetAmount;
  final DateTime deadline;
  final bool achieved;

  _SavingData({
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.deadline,
    required this.achieved,
  });

  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory _SavingData.fromMap(Map<String, dynamic> map) => _SavingData(
        name: map['name'] ?? '',
        savedAmount: (map['savedAmount'] as num?)?.toDouble() ?? 0.0,
        targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
        deadline: map['deadline'] != null
            ? DateTime.parse(map['deadline'])
            : DateTime.now().add(const Duration(days: 30)),
        achieved: map['achieved'] ?? false,
      );
}