import 'dart:async';
import 'dart:convert';

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:final_project/SecondaryScreens/Report/date_preset.dart';
import 'package:final_project/SecondaryScreens/Report/report_budgets_section.dart';
import 'package:final_project/SecondaryScreens/Report/report_collapsible.dart';
import 'package:final_project/SecondaryScreens/Report/report_constants.dart';
import 'package:final_project/SecondaryScreens/Report/report_custom_date_row.dart';
import 'package:final_project/SecondaryScreens/Report/report_daily_spending_bars.dart';
import 'package:final_project/SecondaryScreens/Report/report_date_presets.dart';
import 'package:final_project/SecondaryScreens/Report/report_day_of_week_activity.dart';
import 'package:final_project/SecondaryScreens/Report/report_empty_state.dart';
import 'package:final_project/SecondaryScreens/Report/report_export_button.dart';
import 'package:final_project/SecondaryScreens/Report/report_filters_row.dart';
import 'package:final_project/SecondaryScreens/Report/report_helpers.dart';
import 'package:final_project/SecondaryScreens/Report/report_insights_section.dart';
import 'package:final_project/SecondaryScreens/Report/report_pdf_service.dart';
import 'package:final_project/SecondaryScreens/Report/report_savings_section.dart';
import 'package:final_project/SecondaryScreens/Report/report_spending_category_chart.dart';
import 'package:final_project/SecondaryScreens/Report/report_summary_section.dart';
import 'package:final_project/SecondaryScreens/Report/report_top_expenses.dart';
import 'package:final_project/SecondaryScreens/Report/report_transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Report Page ──────────────────────────────────────────────────────────────
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> transactions = [];
  List<Budget> budgets = [];
  List<Saving> savings = [];
  double totalIncome = 0.0;

  bool isLoading = false;
  bool isGeneratingPDF = false;

  DatePreset selectedPreset = DatePreset.thisMonth;
  DateTime? startDate;
  DateTime? endDate;
  String? selectedBudget;
  String? selectedSaving;
  String? selectedType;

  late TabController _tabController;
  Timer? _refreshTimer;

  bool _summaryExpanded = true;
  bool _insightsExpanded = true;
  bool _budgetsExpanded = true;
  bool _savingsExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _applyPreset(DatePreset.thisMonth);
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

  // ─── Date preset ──────────────────────────────────────────────────────────────
  void _applyPreset(DatePreset preset) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;
    switch (preset) {
      case DatePreset.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case DatePreset.thisWeek:
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        break;
      case DatePreset.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case DatePreset.lastMonth:
        final lm = DateTime(now.year, now.month - 1);
        start = DateTime(lm.year, lm.month, 1);
        end = DateTime(
          now.year,
          now.month,
          1,
        ).subtract(const Duration(days: 1));
        break;
      case DatePreset.last3Months:
        start = DateTime(now.year, now.month - 2, 1);
        break;
      case DatePreset.thisYear:
        start = DateTime(now.year, 1, 1);
        break;
      case DatePreset.custom:
        setState(() => selectedPreset = preset);
        return;
    }
    setState(() {
      selectedPreset = preset;
      startDate = start;
      endDate = end;
    });
  }

  // ─── Load data ────────────────────────────────────────────────────────────────
  Future<void> loadData({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    final newTx = List<Map<String, dynamic>>.from(
      json.decode(prefs.getString(kReportKeyTransactions) ?? '[]'),
    );
    final newBudgets = (prefs.getStringList(kReportKeyBudgets) ?? [])
        .map((s) => Budget.fromMap(json.decode(s)))
        .toList();
    final newSavings = (prefs.getStringList(kReportKeySavings) ?? [])
        .map((s) => Saving.fromMap(json.decode(s)))
        .toList();
    final newIncome = prefs.getDouble(kReportKeyTotalIncome) ?? 0.0;

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

  // ─── Filtered transactions ────────────────────────────────────────────────────
  List<Map<String, dynamic>> get filteredTransactions {
    return transactions.where((tx) {
      final txDate = DateTime.parse(tx['date']);
      if (startDate != null && txDate.isBefore(startDate!)) return false;
      if (endDate != null &&
          txDate.isAfter(endDate!.add(const Duration(days: 1)))) {
        return false;
      }
      if (selectedType != null && selectedType != 'All') {
        if (selectedType == 'Income' && tx['type'] != 'income') return false;
        if (selectedType == 'Expense' && tx['type'] == 'income') return false;
        if (selectedType == 'Savings' &&
            tx['type'] != 'savings_deduction' &&
            tx['type'] != 'saving_deposit') {
          return false;
        }
      }
      if (selectedBudget != null && selectedBudget != 'All') {
        if (!(tx['title'] ?? '').toString().toLowerCase().contains(
          selectedBudget!.toLowerCase(),
        )) {
          return false;
        }
      }
      if (selectedSaving != null && selectedSaving != 'All') {
        if (!(tx['title'] ?? '').toString().toLowerCase().contains(
          selectedSaving!.toLowerCase(),
        )) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ─── Aggregates ───────────────────────────────────────────────────────────────
  double get filteredIncome => filteredTransactions
      .where((tx) => tx['type'] == 'income')
      .fold(0.0, (s, tx) => s + reportAmt(tx));

  double get filteredExpenses => filteredTransactions
      .where(
        (tx) => tx['type'] != 'income' && tx['type'] != 'savings_withdrawal',
      )
      .fold(0.0, (s, tx) {
        final type = (tx['type'] ?? '') as String;
        // For savings_deduction/saving_deposit: 'amount' already = principal+fee.
        // Do NOT add reportFee(tx) again to avoid double-counting.
        if (type == 'savings_deduction' || type == 'saving_deposit') {
          return s + reportAmt(tx);
        }
        return s + reportAmt(tx) + reportFee(tx);
      });

  // filteredSavings: principal only (no fee) for the statistics card display.
  double get filteredSavings => filteredTransactions
      .where(
        (tx) =>
            tx['type'] == 'savings_deduction' || tx['type'] == 'saving_deposit',
      )
      .fold(
        0.0,
        (s, tx) =>
            (s + reportAmt(tx) - reportFee(tx)).clamp(0.0, double.infinity),
      );

  double get totalFeesPaid => filteredTransactions
      .where(
        (tx) => tx['type'] != 'income' && tx['type'] != 'savings_withdrawal',
      )
      .fold(0.0, (s, tx) => s + reportFee(tx));

  double get netBalance => filteredIncome - filteredExpenses;
  double get savingsRate =>
      filteredIncome <= 0 ? 0 : (filteredSavings / filteredIncome) * 100;
  double get expenseRatio =>
      filteredIncome <= 0 ? 0 : (filteredExpenses / filteredIncome) * 100;

  double get avgDailySpend {
    if (startDate == null || endDate == null) return 0;
    final days = endDate!.difference(startDate!).inDays + 1;
    return days <= 0 ? filteredExpenses : filteredExpenses / days;
  }

  double get savingsCompletionRate {
    if (savings.isEmpty) return 0;
    return (savings.where((s) => s.achieved).length / savings.length) * 100;
  }

  Map<String, dynamic>? get biggestExpense {
    final exp = filteredTransactions
        .where(
          (tx) => tx['type'] != 'income' && tx['type'] != 'savings_withdrawal',
        )
        .toList();
    if (exp.isEmpty) return null;
    exp.sort(
      (a, b) =>
          (reportAmt(b) + reportFee(b)).compareTo(reportAmt(a) + reportFee(a)),
    );
    return exp.first;
  }

  Map<String, double> get spendingByCategory {
    final map = <String, double>{};
    for (final tx in filteredTransactions) {
      if (tx['type'] == 'income') continue;
      if (tx['type'] == 'savings_withdrawal') continue;
      final type = (tx['type'] ?? '') as String;
      final label = getTypeLabel(tx['type']);
      // For savings: amount already = principal+fee; do NOT add reportFee again.
      if (type == 'savings_deduction' || type == 'saving_deposit') {
        map[label] = (map[label] ?? 0) + reportAmt(tx);
      } else {
        map[label] = (map[label] ?? 0) + reportAmt(tx) + reportFee(tx);
      }
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  List<DailyTotal> get dailySpending {
    if (startDate == null || endDate == null) return [];
    final map = <String, double>{};
    for (final tx in filteredTransactions) {
      if (tx['type'] == 'income') continue;
      if (tx['type'] == 'savings_withdrawal') continue;
      final type = (tx['type'] ?? '') as String;
      final key = DateFormat('dd/MM').format(DateTime.parse(tx['date']));
      // For savings: amount already = principal+fee; do NOT add reportFee again.
      if (type == 'savings_deduction' || type == 'saving_deposit') {
        map[key] = (map[key] ?? 0) + reportAmt(tx);
      } else {
        map[key] = (map[key] ?? 0) + reportAmt(tx) + reportFee(tx);
      }
    }
    final days = endDate!.difference(startDate!).inDays + 1;
    final result = <DailyTotal>[];
    for (var i = 0; i < days && i < 31; i++) {
      final d = startDate!.add(Duration(days: i));
      final key = DateFormat('dd/MM').format(d);
      result.add(DailyTotal(key, map[key] ?? 0));
    }
    return result;
  }

  List<int> get txByDayOfWeek {
    final counts = List.filled(7, 0);
    for (final tx in filteredTransactions) {
      counts[(DateTime.parse(tx['date']).weekday - 1) % 7]++;
    }
    return counts;
  }

  List<Map<String, dynamic>> get topExpenses {
    final exp =
        filteredTransactions
            .where(
              (tx) =>
                  tx['type'] != 'income' && tx['type'] != 'savings_withdrawal',
            )
            .toList()
          ..sort(
            (a, b) => (reportAmt(b) + reportFee(b)).compareTo(
              reportAmt(a) + reportFee(a),
            ),
          );
    return exp.take(5).toList();
  }

  Map<String, List<Map<String, dynamic>>> get groupedTransactions {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var tx in filteredTransactions) {
      final key = DateFormat('dd MMM yyyy').format(DateTime.parse(tx['date']));
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  double get projectedMonthEndSpend {
    final now = DateTime.now();
    final dayOfMonth = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    if (dayOfMonth == 0) return filteredExpenses;
    return (filteredExpenses / dayOfMonth) * daysInMonth;
  }

  Map<String, double> get priorPeriodExpenses {
    if (startDate == null || endDate == null) {
      return {'prior': 0, 'current': filteredExpenses};
    }
    final duration = endDate!.difference(startDate!);
    final priorEnd = startDate!.subtract(const Duration(days: 1));
    final priorStart = priorEnd.subtract(duration);
    double prior = 0;
    for (final tx in transactions) {
      if (tx['type'] == 'income') continue;
      final d = DateTime.parse(tx['date']);
      if (d.isAfter(priorStart) &&
          d.isBefore(priorEnd.add(const Duration(days: 1)))) {
        prior += reportAmt(tx) + reportFee(tx);
      }
    }
    return {'prior': prior, 'current': filteredExpenses};
  }

  // ─── PDF Export ───────────────────────────────────────────────────────────────
  Future<void> generatePDF() async {
    if (startDate == null || endDate == null) return;
    setState(() => isGeneratingPDF = true);
    await ReportPdfService(
      startDate: startDate!,
      endDate: endDate!,
      filteredTransactions: filteredTransactions,
      filteredIncome: filteredIncome,
      filteredExpenses: filteredExpenses,
      filteredSavings: filteredSavings,
      netBalance: netBalance,
      avgDailySpend: avgDailySpend,
      totalFeesPaid: totalFeesPaid,
      savingsRate: savingsRate,
      spendingByCategory: spendingByCategory,
      budgets: budgets,
      savings: savings,
    ).generate(context);
    if (mounted) setState(() => isGeneratingPDF = false);
  }

  // ─── Preset change handler ────────────────────────────────────────────────────
  void _onPresetChanged(DatePreset preset) {
    if (preset == DatePreset.custom) {
      setState(() => selectedPreset = DatePreset.custom);
    } else {
      _applyPreset(preset);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Financial Report'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_outlined, size: 18),
              text: 'Overview',
            ),
            Tab(
              icon: Icon(Icons.bar_chart_rounded, size: 18),
              text: 'Analytics',
            ),
            Tab(
              icon: Icon(Icons.receipt_long_outlined, size: 18),
              text: 'Transactions',
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(theme),
                _buildAnalyticsTab(theme),
                _buildTransactionsTab(theme),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab(ThemeData theme) {
    final comparison = priorPeriodExpenses;

    return RefreshIndicator(
      onRefresh: loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: paddingAllMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportDatePresets(
              selectedPreset: selectedPreset,
              onPresetChanged: _onPresetChanged,
            ),
            if (selectedPreset == DatePreset.custom) ...[
              sizedBoxHeightSmall,
              ReportCustomDateRow(
                startDate: startDate,
                endDate: endDate,
                onStartDateChanged: (d) => setState(() => startDate = d),
                onEndDateChanged: (d) => setState(() => endDate = d),
              ),
            ],
            sizedBoxHeightSmall,
            ReportFiltersRow(
              selectedType: selectedType,
              selectedBudget: selectedBudget,
              selectedSaving: selectedSaving,
              budgets: budgets,
              savings: savings,
              onTypeChanged: (v) => setState(() => selectedType = v),
              onBudgetChanged: (v) => setState(() => selectedBudget = v),
              onSavingChanged: (v) => setState(() => selectedSaving = v),
            ),
            sizedBoxHeightLarge,
            ReportCollapsible(
              title: 'Summary',
              expanded: _summaryExpanded,
              onTap: () => setState(() => _summaryExpanded = !_summaryExpanded),
              child: ReportSummarySection(
                netBalance: netBalance,
                filteredIncome: filteredIncome,
                filteredExpenses: filteredExpenses,
                filteredSavings: filteredSavings,
                expenseRatio: expenseRatio,
                avgDailySpend: avgDailySpend,
                totalFeesPaid: totalFeesPaid,
                savingsRate: savingsRate,
                transactionCount: filteredTransactions.length,
                priorExpenses: comparison['prior'] ?? 0,
              ),
            ),
            sizedBoxHeightMedium,
            ReportCollapsible(
              title: 'Key Insights',
              expanded: _insightsExpanded,
              onTap: () =>
                  setState(() => _insightsExpanded = !_insightsExpanded),
              child: ReportInsightsSection(
                filteredExpenses: filteredExpenses,
                priorExpenses: comparison['prior'] ?? 0,
                selectedPreset: selectedPreset,
                projectedMonthEndSpend: projectedMonthEndSpend,
                biggestExpense: biggestExpense,
                savings: savings,
                totalFeesPaid: totalFeesPaid,
              ),
            ),
            sizedBoxHeightMedium,
            ReportCollapsible(
              title: 'Budget Status',
              expanded: _budgetsExpanded,
              onTap: () => setState(() => _budgetsExpanded = !_budgetsExpanded),
              child: ReportBudgetsSection(budgets: budgets),
            ),
            sizedBoxHeightMedium,
            ReportCollapsible(
              title: 'Savings Goals',
              expanded: _savingsExpanded,
              onTap: () => setState(() => _savingsExpanded = !_savingsExpanded),
              child: ReportSavingsSection(savings: savings),
            ),
            sizedBoxHeightLarge,
            ReportExportButton(
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
  // TAB 2: ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAnalyticsTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: paddingAllMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportDatePresets(
              selectedPreset: selectedPreset,
              onPresetChanged: _onPresetChanged,
            ),
            sizedBoxHeightLarge,
            ReportSpendingCategoryChart(spendingByCategory: spendingByCategory),
            sizedBoxHeightLarge,
            ReportDailySpendingBars(
              dailySpending: dailySpending,
              filteredExpenses: filteredExpenses,
              avgDailySpend: avgDailySpend,
            ),
            sizedBoxHeightLarge,
            ReportDayOfWeekActivity(txByDayOfWeek: txByDayOfWeek),
            sizedBoxHeightLarge,
            ReportTopExpenses(topExpenses: topExpenses),
            sizedBoxHeightLarge,
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: TRANSACTIONS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTransactionsTab(ThemeData theme) {
    final grouped = groupedTransactions;

    return RefreshIndicator(
      onRefresh: loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: paddingAllMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportDatePresets(
              selectedPreset: selectedPreset,
              onPresetChanged: _onPresetChanged,
            ),
            if (selectedPreset == DatePreset.custom) ...[
              sizedBoxHeightSmall,
              ReportCustomDateRow(
                startDate: startDate,
                endDate: endDate,
                onStartDateChanged: (d) => setState(() => startDate = d),
                onEndDateChanged: (d) => setState(() => endDate = d),
              ),
            ],
            sizedBoxHeightSmall,
            ReportFiltersRow(
              selectedType: selectedType,
              selectedBudget: selectedBudget,
              selectedSaving: selectedSaving,
              budgets: budgets,
              savings: savings,
              onTypeChanged: (v) => setState(() => selectedType = v),
              onBudgetChanged: (v) => setState(() => selectedBudget = v),
              onSavingChanged: (v) => setState(() => selectedSaving = v),
            ),
            sizedBoxHeightMedium,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredTransactions.length} transaction${filteredTransactions.length == 1 ? '' : 's'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(filteredExpenses),
                  style: const TextStyle(
                    color: errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            sizedBoxHeightMedium,
            if (grouped.isEmpty)
              const ReportEmptyState(
                title: 'No transactions found',
                subtitle: 'Try adjusting your filters or date range',
              )
            else
              ...grouped.entries.map(
                (entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${entry.value.length} tx',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...entry.value.map((tx) => ReportTransactionCard(tx: tx)),
                    sizedBoxHeightSmall,
                  ],
                ),
              ),
            sizedBoxHeightLarge,
          ],
        ),
      ),
    );
  }
}
