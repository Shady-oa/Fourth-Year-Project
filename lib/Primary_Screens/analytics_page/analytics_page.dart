import 'dart:async';
import 'dart:convert';

import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_budget_health.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_category_pie_section.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_custom_date_row.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_day_of_week_heatmap.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_filter_chips.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_helpers.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_insight_card.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_kpi_strip.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_monthly_comparison.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_monthly_trend_chart.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_pdf_button.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_pdf_service.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_savings_progress.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_spending_category_table.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_summary_hero.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_top_expenses.dart';
import 'package:flutter/material.dart';
import 'package:final_project/SecondaryScreens/Report/report_page.dart' as report;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Analytics Page ───────────────────────────────────────────────────────────
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  static const String keyTransactions = 'transactions';
  static const String keyBudgets = 'budgets';
  static const String keySavings = 'savings';
  static const String keyTotalIncome = 'total_income';

  List<Map<String, dynamic>> transactions = [];
  List<Budget> budgets = [];
  List<Saving> savings = [];
  double totalIncome = 0.0;

  bool isLoading = false;
  bool isGeneratingPDF = false;
  String selectedFilter = 'This Month';
  DateTime? customStartDate;
  DateTime? customEndDate;

  Timer? _refreshTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => loadData(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ─── Load data ─────────────────────────────────────────────────────────────
  Future<void> loadData({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    final newTx = List<Map<String, dynamic>>.from(
      json.decode(prefs.getString(keyTransactions) ?? '[]'),
    );
    final newBudgets = (prefs.getStringList(keyBudgets) ?? [])
        .map((s) => Budget.fromMap(json.decode(s)))
        .toList();
    final newSavings = (prefs.getStringList(keySavings) ?? [])
        .map((s) => Saving.fromMap(json.decode(s)))
        .toList();
    final newIncome = prefs.getDouble(keyTotalIncome) ?? 0.0;

    if (mounted) {
      setState(() {
        transactions = newTx;
        budgets = newBudgets;
        savings = newSavings;
        totalIncome = newIncome;
        isLoading = false;
      });
    }
  }

  // ─── Filtered transactions ─────────────────────────────────────────────────
  List<Map<String, dynamic>> get filteredTransactions {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (selectedFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Last 7 Days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 2, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'Custom':
        if (customStartDate == null || customEndDate == null) {
          return transactions;
        }
        startDate = customStartDate!;
        endDate = customEndDate!;
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return transactions.where((tx) {
      final d = DateTime.parse(tx['date']);
      return d.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          d.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();
  }

  // ─── Computed values ───────────────────────────────────────────────────────
  double get filteredIncome => filteredTransactions
      .where((tx) => tx['type'] == 'income')
      .fold(0.0, (s, tx) => s + analyticsAmt(tx));

  double get filteredExpenses => filteredTransactions
      .where(
        (tx) => tx['type'] != 'income' && tx['type'] != 'savings_withdrawal',
      )
      .fold(0.0, (s, tx) {
        final type = (tx['type'] ?? '') as String;
        if (type == 'savings_deduction' || type == 'saving_deposit') {
          return s + analyticsAmt(tx);
        }
        return s + analyticsAmt(tx) + analyticsFee(tx);
      });

  double get filteredSavings => filteredTransactions
      .where(
        (tx) =>
            tx['type'] == 'savings_deduction' || tx['type'] == 'saving_deposit',
      )
      .fold(
        0.0,
        (s, tx) => (s + analyticsAmt(tx) - analyticsFee(tx)).clamp(
          0.0,
          double.infinity,
        ),
      );

  double get totalFeesPaid => filteredTransactions
      .where(
        (tx) => tx['type'] != 'income' && tx['type'] != 'savings_withdrawal',
      )
      .fold(0.0, (s, tx) => s + analyticsFee(tx));

  double get netBalance => filteredIncome - filteredExpenses;

  double get savingsRate =>
      filteredIncome > 0 ? (filteredSavings / filteredIncome) * 100 : 0;

  double get expenseRatio =>
      filteredIncome > 0 ? (filteredExpenses / filteredIncome) * 100 : 0;

  double get avgDailySpend {
    final now = DateTime.now();
    final start = selectedFilter == 'This Month'
        ? DateTime(now.year, now.month, 1)
        : selectedFilter == 'Last 7 Days'
        ? now.subtract(const Duration(days: 7))
        : selectedFilter == 'Today'
        ? DateTime(now.year, now.month, now.day)
        : customStartDate ?? DateTime(now.year, now.month, 1);
    final days = now.difference(start).inDays + 1;
    return days > 0 ? filteredExpenses / days : 0;
  }

  double get projectedMonthEndSpend {
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    if (dayOfMonth == 0) return filteredExpenses;
    return (filteredExpenses / dayOfMonth) * daysInMonth;
  }

  // ─── Category breakdown ───────────────────────────────────────────────────────
  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (var tx in filteredTransactions) {
      if (tx['type'] == 'income') continue;
      final type = (tx['type'] ?? '') as String;
      final cat = categoriseTitle(tx['title'] ?? '');
      if (type == 'savings_deduction' || type == 'saving_deposit') {
        map[cat] = (map[cat] ?? 0) + analyticsAmt(tx);
      } else {
        map[cat] = (map[cat] ?? 0) + analyticsAmt(tx) + analyticsFee(tx);
      }
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  // ─── Monthly data (last 6 months) ─────────────────────────────────────────────
  List<Map<String, dynamic>> get last6MonthsData {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);
      final label = _monthLabel(month);
      double income = 0, expenses = 0, savingsAmt = 0;
      for (final tx in transactions) {
        final d = DateTime.parse(tx['date']);
        if (d.isBefore(month) || d.isAfter(monthEnd)) continue;
        if (tx['type'] == 'income') {
          income += analyticsAmt(tx);
        } else if (tx['type'] == 'savings_withdrawal') {
          continue;
        } else if (tx['type'] == 'savings_deduction' ||
            tx['type'] == 'saving_deposit') {
          savingsAmt += (analyticsAmt(tx) - analyticsFee(tx)).clamp(
            0.0,
            double.infinity,
          );
          expenses += analyticsAmt(tx);
        } else {
          expenses += analyticsAmt(tx) + analyticsFee(tx);
        }
      }
      result.add({
        'label': label,
        'income': income,
        'expenses': expenses,
        'savings': savingsAmt,
      });
    }
    return result;
  }

  String _monthLabel(DateTime month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month.month - 1];
  }

  Map<String, dynamic> get monthlyComparison {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    double thisMonthExp = 0, lastMonthExp = 0;
    double thisMonthInc = 0, lastMonthInc = 0;

    for (var tx in transactions) {
      final d = DateTime.parse(tx['date']);
      if (tx['type'] == 'income') {
        if (d.isAfter(thisMonthStart)) {
          thisMonthInc += analyticsAmt(tx);
        } else if (d.isAfter(lastMonthStart) && d.isBefore(lastMonthEnd)) {
          lastMonthInc += analyticsAmt(tx);
        }
      } else if (tx['type'] == 'savings_withdrawal') {
        continue;
      } else {
        final isS =
            tx['type'] == 'savings_deduction' || tx['type'] == 'saving_deposit';
        final cost = isS
            ? analyticsAmt(tx)
            : analyticsAmt(tx) + analyticsFee(tx);
        if (d.isAfter(thisMonthStart)) {
          thisMonthExp += cost;
        } else if (d.isAfter(lastMonthStart) && d.isBefore(lastMonthEnd)) {
          lastMonthExp += cost;
        }
      }
    }

    final changeAmt = thisMonthExp - lastMonthExp;
    final changePct = lastMonthExp == 0
        ? 0.0
        : (changeAmt / lastMonthExp) * 100;

    return {
      'thisMonthExp': thisMonthExp,
      'lastMonthExp': lastMonthExp,
      'thisMonthInc': thisMonthInc,
      'lastMonthInc': lastMonthInc,
      'change': changePct,
      'changeAmt': changeAmt,
    };
  }

  List<Map<String, dynamic>> get topExpenses {
    final exp =
        filteredTransactions.where((tx) => tx['type'] != 'income').toList()
          ..sort(
            (a, b) => (analyticsAmt(b) + analyticsFee(b)).compareTo(
              analyticsAmt(a) + analyticsFee(a),
            ),
          );
    return exp.take(5).toList();
  }

  // ─── Smart Insights ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get smartInsights {
    final list = <Map<String, dynamic>>[];
    final cmp = monthlyComparison;
    final change = cmp['change'] as double;

    if ((change).abs() > 5) {
      list.add({
        'icon': change > 0 ? Icons.trending_up : Icons.trending_down,
        'color': change > 0 ? errorColor : brandGreen,
        'title': change > 0
            ? 'Spending up ${change.toStringAsFixed(1)}% vs last month'
            : 'Spending down ${change.abs().toStringAsFixed(1)}% vs last month',
        'detail':
            '${CurrencyFormatter.compact(cmp['thisMonthExp'])} this month vs ${CurrencyFormatter.compact(cmp['lastMonthExp'])} last month',
        'good': change < 0,
      });
    }

    if (savingsRate > 0) {
      list.add({
        'icon': savingsRate >= 20 ? Icons.star_rounded : Icons.savings_outlined,
        'color': savingsRate >= 20 ? Colors.amber.shade600 : accentColor,
        'title': savingsRate >= 20
            ? 'Excellent savings rate: ${savingsRate.toStringAsFixed(1)}%'
            : 'Savings rate: ${savingsRate.toStringAsFixed(1)}% (target: 20%)',
        'detail':
            'You saved ${CurrencyFormatter.compact(filteredSavings)} this period',
        'good': savingsRate >= 20,
      });
    }

    if (selectedFilter == 'This Month' &&
        projectedMonthEndSpend > filteredIncome &&
        filteredIncome > 0) {
      list.add({
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orange,
        'title': 'On track to overspend this month',
        'detail':
            'Projected: ${CurrencyFormatter.compact(projectedMonthEndSpend)} vs income ${CurrencyFormatter.compact(filteredIncome)}',
        'good': false,
      });
    }

    final cats = expensesByCategory;
    if (cats.isNotEmpty) {
      final topCat = cats.entries.first;
      final topPct = filteredExpenses > 0
          ? topCat.value / filteredExpenses * 100
          : 0.0;
      list.add({
        'icon': Icons.donut_small,
        'color': Colors.purple,
        'title':
            '${topCat.key} is your top spend: ${topPct.toStringAsFixed(0)}%',
        'detail':
            '${CurrencyFormatter.compact(topCat.value)} out of ${CurrencyFormatter.compact(filteredExpenses)}',
        'good': topPct < 50,
      });
    }

    if (totalFeesPaid > filteredExpenses * 0.05) {
      list.add({
        'icon': Icons.receipt_outlined,
        'color': Colors.orange,
        'title':
            'High transaction fees: ${(totalFeesPaid / filteredExpenses * 100).toStringAsFixed(1)}% of spend',
        'detail':
            '${CurrencyFormatter.format(totalFeesPaid)} lost to fees this period',
        'good': false,
      });
    }

    for (final s in savings) {
      if (!s.achieved) {
        final daysLeft = s.deadline.difference(DateTime.now()).inDays;
        if (daysLeft >= 0 && daysLeft <= 7) {
          list.add({
            'icon': Icons.timer,
            'color': daysLeft <= 3 ? errorColor : Colors.orange,
            'title':
                '${s.name} goal due in $daysLeft day${daysLeft == 1 ? '' : 's'}',
            'detail':
                '${(s.progressPercent * 100).toStringAsFixed(0)}% complete — ${CurrencyFormatter.format(s.savedAmount)} saved',
            'good': false,
          });
        }
        if (s.progressPercent >= 0.9) {
          list.add({
            'icon': Icons.flag_rounded,
            'color': brandGreen,
            'title':
                'Almost there! ${(s.progressPercent * 100).toStringAsFixed(0)}% of ${s.name}',
            'detail': 'Only ${CurrencyFormatter.format(s.balance)} remaining',
            'good': true,
          });
        }
      }
    }

    list.add({
      'icon': Icons.today,
      'color': accentColor,
      'title': 'Avg daily spend: ${CurrencyFormatter.compact(avgDailySpend)}',
      'detail': selectedFilter == 'This Month'
          ? 'Projected month-end: ${CurrencyFormatter.compact(projectedMonthEndSpend)}'
          : 'Over the selected period',
      'good': true,
    });

    if (list.isEmpty) {
      list.add({
        'icon': Icons.lightbulb_outline,
        'color': accentColor,
        'title': 'Add more transactions to unlock insights',
        'detail':
            'Track income, expenses and savings to see personalised analytics.',
        'good': true,
      });
    }

    return list;
  }

  // ─── PDF ─────────────────────────────────────────────────────────────────────
  Future<void> generatePDF() async {
    setState(() => isGeneratingPDF = true);
    try {
      final service = AnalyticsPdfService(
        selectedFilter: selectedFilter,
        filteredIncome: filteredIncome,
        filteredExpenses: filteredExpenses,
        filteredSavings: filteredSavings,
        netBalance: netBalance,
        savingsRate: savingsRate,
        expenseRatio: expenseRatio,
        avgDailySpend: avgDailySpend,
        totalFeesPaid: totalFeesPaid,
        projectedMonthEndSpend: projectedMonthEndSpend,
        last6MonthsData: last6MonthsData,
        expensesByCategory: expensesByCategory,
        monthlyComparison: monthlyComparison,
        budgets: budgets,
        savings: savings.map((s) => report.Saving(
          name: s.name,
          savedAmount: s.savedAmount,
          targetAmount: s.targetAmount,
          deadline: s.deadline,
          achieved: s.achieved,
          lastUpdated: s.lastUpdated,
          transactions: s.transactions,
        )).toList(),
        smartInsights: smartInsights,
      );
      await service.generate(context);
    } finally {
      if (mounted) setState(() => isGeneratingPDF = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const CustomHeader(headerName: 'Analytics'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.insights, size: 18), text: 'Overview'),
            Tab(
              icon: Icon(Icons.lightbulb_outline, size: 18),
              text: 'Insights',
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: isGeneratingPDF ? null : generatePDF,
            icon: isGeneratingPDF
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            tooltip: 'Share Analytics PDF',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildOverviewTab(theme), _buildInsightsTab(theme)],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: paddingAllMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalyticsFilterChips(
              selectedFilter: selectedFilter,
              onFilterChanged: (f) => setState(() => selectedFilter = f),
            ),
            if (selectedFilter == 'Custom') ...[
              sizedBoxHeightSmall,
              AnalyticsCustomDateRow(
                customStartDate: customStartDate,
                customEndDate: customEndDate,
                onStartDateChanged: (d) => setState(() => customStartDate = d),
                onEndDateChanged: (d) => setState(() => customEndDate = d),
              ),
            ],
            sizedBoxHeightLarge,
            AnalyticsSummaryHero(
              selectedFilter: selectedFilter,
              netBalance: netBalance,
              filteredIncome: filteredIncome,
              filteredExpenses: filteredExpenses,
              filteredSavings: filteredSavings,
              expenseRatio: expenseRatio,
              savingsRate: savingsRate,
              avgDailySpend: avgDailySpend,
              totalFeesPaid: totalFeesPaid,
              transactionCount: filteredTransactions.length,
              goalsAchieved: savings.where((s) => s.achieved).length,
              totalGoals: savings.length,
            ),
            sizedBoxHeightLarge,
            AnalyticsMonthlyTrendChart(last6MonthsData: last6MonthsData),
            sizedBoxHeightLarge,
            AnalyticsCategoryPieSection(expensesByCategory: expensesByCategory),
            sizedBoxHeightLarge,
            AnalyticsBudgetHealth(budgets: budgets),
            sizedBoxHeightLarge,
            AnalyticsSavingsProgress(savings: savings),
            sizedBoxHeightLarge,
            AnalyticsTopExpenses(topExpenses: topExpenses),
            sizedBoxHeightLarge,
            AnalyticsMonthlyComparison(monthlyComparison: monthlyComparison),
            sizedBoxHeightLarge,
            AnalyticsPdfButton(
              isGeneratingPDF: isGeneratingPDF,
              onPressed: generatePDF,
            ),
            sizedBoxHeightLarge,
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: INSIGHTS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInsightsTab(ThemeData theme) {
    final insights = smartInsights;
    return RefreshIndicator(
      onRefresh: loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: paddingAllMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalyticsFilterChips(
              selectedFilter: selectedFilter,
              onFilterChanged: (f) => setState(() => selectedFilter = f),
            ),
            sizedBoxHeightLarge,
            AnalyticsKpiStrip(
              netBalance: netBalance,
              savingsRate: savingsRate,
              expenseRatio: expenseRatio,
              avgDailySpend: avgDailySpend,
              totalFeesPaid: totalFeesPaid,
              projectedMonthEndSpend: projectedMonthEndSpend,
            ),
            sizedBoxHeightLarge,
            Text(
              'Personalised Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            sizedBoxHeightMedium,
            ...insights.map(
              (insight) => AnalyticsInsightCard(insight: insight),
            ),
            sizedBoxHeightLarge,
            AnalyticsSpendingCategoryTable(
              expensesByCategory: expensesByCategory,
            ),
            sizedBoxHeightLarge,
            AnalyticsDayOfWeekHeatmap(
              filteredTransactions: filteredTransactions,
            ),
            sizedBoxHeightLarge,
          ],
        ),
      ),
    );
  }
}
