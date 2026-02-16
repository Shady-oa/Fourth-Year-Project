import 'dart:async';
import 'dart:convert';

import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');
  static String format(double amount) =>
      'Ksh ${_formatter.format(amount.round())}';
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  static const String keyTransactions = 'transactions';
  static const String keyBudgets = 'budgets';
  static const String keySavings = 'savings';
  static const String keyTotalIncome = 'total_income';

  List<Map<String, dynamic>> transactions = [];
  List<Budget> budgets = [];
  List<Saving> savings = [];
  double totalIncome = 0.0;

  bool isLoading = true;
  String selectedFilter = 'This Month';
  DateTime? customStartDate;
  DateTime? customEndDate;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      loadData(silent: true);
    });
  }

  Future<void> loadData({bool silent = false}) async {
    if (!silent) setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    final txString = prefs.getString(keyTransactions) ?? '[]';
    final newTransactions =
        List<Map<String, dynamic>>.from(json.decode(txString));

    final budgetStrings = prefs.getStringList(keyBudgets) ?? [];
    final newBudgets =
        budgetStrings.map((s) => Budget.fromMap(json.decode(s))).toList();

    final savingsStrings = prefs.getStringList(keySavings) ?? [];
    final newSavings = savingsStrings
        .map((s) => Saving.fromMap(json.decode(s)))
        .toList();

    final newTotalIncome = prefs.getDouble(keyTotalIncome) ?? 0.0;

    if (mounted) {
      setState(() {
        transactions = newTransactions;
        budgets = newBudgets;
        savings = newSavings;
        totalIncome = newTotalIncome;
        isLoading = false;
      });
    }
  }

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
      final txDate = DateTime.parse(tx['date']);
      return txDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          txDate.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();
  }

  double get filteredIncome {
    return filteredTransactions
        .where((tx) => tx['type'] == 'income')
        .fold(0.0, (sum, tx) => sum + (double.tryParse(tx['amount'].toString()) ?? 0.0));
  }

  double get filteredExpenses {
    return filteredTransactions
        .where((tx) =>
            tx['type'] == 'expense' ||
            tx['type'] == 'budget_finalized' ||
            tx['type'] == 'savings_deduction' ||
            tx['type'] == 'saving_deposit')
        .fold(0.0, (sum, tx) => sum + (double.tryParse(tx['amount'].toString()) ?? 0.0));
  }

  double get filteredSavings {
    return filteredTransactions
        .where((tx) =>
            tx['type'] == 'savings_deduction' || tx['type'] == 'saving_deposit')
        .fold(0.0, (sum, tx) => sum + (double.tryParse(tx['amount'].toString()) ?? 0.0));
  }

  Map<String, double> get expensesByCategory {
    final categories = <String, double>{};

    for (var tx in filteredTransactions) {
      if (tx['type'] == 'expense' ||
          tx['type'] == 'budget_finalized' ||
          tx['type'] == 'savings_deduction') {
        final category = _getCategoryFromTitle(tx['title']);
        categories[category] =
            (categories[category] ?? 0) + (double.tryParse(tx['amount'].toString()) ?? 0.0);
      }
    }

    return categories;
  }

  String _getCategoryFromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('food') ||
        lower.contains('lunch') ||
        lower.contains('dinner') ||
        lower.contains('breakfast')) return 'Food';
    if (lower.contains('transport') ||
        lower.contains('uber') ||
        lower.contains('taxi') ||
        lower.contains('fuel')) return 'Transport';
    if (lower.contains('rent') || lower.contains('house')) return 'Rent';
    if (lower.contains('entertainment') ||
        lower.contains('movie') ||
        lower.contains('game')) return 'Entertainment';
    if (lower.contains('saved for')) return 'Savings';
    return 'Others';
  }

  List<Map<String, dynamic>> get topExpenses {
    final expenses = filteredTransactions
        .where((tx) => tx['type'] != 'income')
        .toList();
    expenses.sort((a, b) {
      final aAmount = double.tryParse(a['amount'].toString()) ?? 0.0;
      final bAmount = double.tryParse(b['amount'].toString()) ?? 0.0;
      return bAmount.compareTo(aAmount);
    });
    return expenses.take(3).toList();
  }

  String get highestExpenseCategory {
    final categories = expensesByCategory;
    if (categories.isEmpty) return 'None';
    final highest = categories.entries.reduce((a, b) => a.value > b.value ? a : b);
    return highest.key;
  }

  Budget? get mostActiveBudget {
    if (budgets.isEmpty) return null;
    budgets.sort((a, b) => b.expenses.length.compareTo(a.expenses.length));
    return budgets.first;
  }

  Map<String, dynamic> get monthlyComparison {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    double thisMonthExpenses = 0;
    double lastMonthExpenses = 0;

    for (var tx in transactions) {
      final txDate = DateTime.parse(tx['date']);
      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;

      if (tx['type'] != 'income') {
        if (txDate.isAfter(thisMonthStart)) {
          thisMonthExpenses += amount;
        } else if (txDate.isAfter(lastMonthStart) &&
            txDate.isBefore(lastMonthEnd)) {
          lastMonthExpenses += amount;
        }
      }
    }

    final change = lastMonthExpenses == 0
        ? 0.0
        : ((thisMonthExpenses - lastMonthExpenses) / lastMonthExpenses) * 100;

    return {
      'thisMonth': thisMonthExpenses,
      'lastMonth': lastMonthExpenses,
      'change': change,
    };
  }

  List<String> get smartInsights {
    final insights = <String>[];
    final comparison = monthlyComparison;
    final change = comparison['change'] as double;

    if (change > 10) {
      insights.add(
          'You spent ${change.toStringAsFixed(1)}% more than last month. Consider reviewing your expenses.');
    } else if (change < -10) {
      insights.add(
          'Great job! You spent ${change.abs().toStringAsFixed(1)}% less than last month.');
    }

    final savingsRate = filteredIncome == 0
        ? 0.0
        : (filteredSavings / filteredIncome) * 100;
    if (savingsRate > 20) {
      insights.add(
          'Excellent! You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income.');
    } else if (savingsRate > 0 && savingsRate < 10) {
      insights.add(
          'Your savings rate is ${savingsRate.toStringAsFixed(1)}%. Try to increase it to 20%.');
    }

    for (var saving in savings) {
      if (!saving.achieved) {
        final progress = (saving.savedAmount / saving.targetAmount) * 100;
        if (progress > 80) {
          insights.add(
              'You\'re ${progress.toStringAsFixed(0)}% towards your ${saving.name} goal!');
        }
      }
    }

    final highestCategory = highestExpenseCategory;
    if (highestCategory != 'None') {
      final categoryAmount = expensesByCategory[highestCategory] ?? 0;
      final percentage = filteredExpenses == 0
          ? 0.0
          : (categoryAmount / filteredExpenses) * 100;
      insights.add(
          '$highestCategory accounts for ${percentage.toStringAsFixed(0)}% of your expenses.');
    }

    if (insights.isEmpty) {
      insights.add('Start tracking more transactions to get personalized insights.');
    }

    return insights;
  }

  Color getBudgetHealthColor(Budget budget) {
    final percentage = (budget.totalSpent / budget.total) * 100;
    if (percentage < 70) return brandGreen;
    if (percentage < 90) return Colors.orange;
    return errorColor;
  }

  String getBudgetHealthLabel(Budget budget) {
    final percentage = (budget.totalSpent / budget.total) * 100;
    if (percentage < 70) return 'Safe';
    if (percentage < 90) return 'Warning';
    return 'Over Budget';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const CustomHeader(headerName: "Analytics"),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: paddingAllMedium,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildFilterSection(theme),
                    sizedBoxHeightLarge,
                    buildSummaryCards(theme),
                    sizedBoxHeightLarge,
                    buildBarChart(theme),
                    sizedBoxHeightLarge,
                    buildPieChart(theme),
                    sizedBoxHeightLarge,
                    buildSavingsProgress(theme),
                    sizedBoxHeightLarge,
                    buildMonthlyComparison(theme),
                    sizedBoxHeightLarge,
                    buildBudgetHealth(theme),
                    sizedBoxHeightLarge,
                    buildTopExpenses(theme),
                    sizedBoxHeightLarge,
                    buildSmartInsights(theme),
                    sizedBoxHeightLarge,
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildFilterSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time Period',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
        sizedBoxHeightSmall,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            buildFilterChip('Today'),
            buildFilterChip('Last 7 Days'),
            buildFilterChip('This Month'),
            buildFilterChip('Custom'),
          ],
        ),
        if (selectedFilter == 'Custom') ...[
          sizedBoxHeightSmall,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: customStartDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => customStartDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    customStartDate == null
                        ? 'Start Date'
                        : DateFormat('dd MMM').format(customStartDate!),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: customEndDate ?? DateTime.now(),
                      firstDate: customStartDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => customEndDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    customEndDate == null
                        ? 'End Date'
                        : DateFormat('dd MMM').format(customEndDate!),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? brandGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? brandGreen : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget buildSummaryCards(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary',
            style:
                theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        sizedBoxHeightSmall,
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                'Income',
                filteredIncome,
                Icons.arrow_circle_down_rounded,
                brandGreen,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildSummaryCard(
                'Expenses',
                filteredExpenses,
                Icons.arrow_circle_up_rounded,
                errorColor,
                theme,
              ),
            ),
          ],
        ),
        sizedBoxHeightSmall,
        Row(
          children: [
            Expanded(
              child: buildSummaryCard(
                'Savings',
                filteredSavings,
                Icons.savings,
                accentColor,
                theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildSummaryCard(
                'Net Balance',
                filteredIncome - filteredExpenses,
                Icons.account_balance_wallet,
                filteredIncome - filteredExpenses >= 0
                    ? brandGreen
                    : errorColor,
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildSummaryCard(
      String label, double amount, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radiusSmall,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          sizedBoxHeightSmall,
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBarChart(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radiusSmall,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Income vs Expenses vs Savings',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          sizedBoxHeightMedium,
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: [filteredIncome, filteredExpenses, filteredSavings]
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Income',
                                style: TextStyle(fontSize: 10));
                          case 1:
                            return const Text('Expenses',
                                style: TextStyle(fontSize: 10));
                          case 2:
                            return const Text('Savings',
                                style: TextStyle(fontSize: 10));
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}K',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: filteredIncome,
                        color: brandGreen,
                        width: 40,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: filteredExpenses,
                        color: errorColor,
                        width: 40,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: filteredSavings,
                        color: accentColor,
                        width: 40,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPieChart(ThemeData theme) {
    final categories = expensesByCategory;
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: radiusSmall,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text('No expense data available',
              style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.green,
      Colors.red,
      Colors.teal,
    ];

    int colorIndex = 0;
    final sections = categories.entries.map((entry) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      final percentage = (entry.value / filteredExpenses) * 100;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radiusSmall,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expense Distribution',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          sizedBoxHeightMedium,
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categories.entries.map((entry) {
                    final color =
                        colors[categories.keys.toList().indexOf(entry.key) %
                            colors.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSavingsProgress(ThemeData theme) {
    if (savings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radiusSmall,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Savings Goals Progress',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          sizedBoxHeightMedium,
          ...savings.map((saving) {
            final progress =
                (saving.savedAmount / saving.targetAmount).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(saving.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: saving.achieved ? brandGreen : accentColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        saving.achieved ? brandGreen : accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrencyFormatter.format(saving.savedAmount)} / ${CurrencyFormatter.format(saving.targetAmount)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget buildMonthlyComparison(ThemeData theme) {
    final comparison = monthlyComparison;
    final change = comparison['change'] as double;
    final isIncrease = change > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radiusSmall,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Comparison',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          sizedBoxHeightMedium,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This Month',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(comparison['thisMonth']),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last Month',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(comparison['lastMonth']),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          sizedBoxHeightSmall,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isIncrease
                  ? Colors.red.shade50
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isIncrease ? Icons.trending_up : Icons.trending_down,
                  color: isIncrease ? errorColor : brandGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${change.abs().toStringAsFixed(1)}% ${isIncrease ? 'increase' : 'decrease'} from last month',
                    style: TextStyle(
                      fontSize: 12,
                      color: isIncrease ? errorColor : brandGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBudgetHealth(ThemeData theme) {
    if (budgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radiusSmall,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Health',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          sizedBoxHeightMedium,
          ...budgets.map((budget) {
            final color = getBudgetHealthColor(budget);
            final label = getBudgetHealthLabel(budget);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(budget.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '${CurrencyFormatter.format(budget.totalSpent)} / ${CurrencyFormatter.format(budget.total)}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget buildTopExpenses(ThemeData theme) {
    final top = topExpenses;
    if (top.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radiusSmall,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top 3 Highest Expenses',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          sizedBoxHeightMedium,
          ...top.asMap().entries.map((entry) {
            final index = entry.key;
            final tx = entry.value;
            final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
            final medals = ['🥇', '🥈', '🥉'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(medals[index], style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx['title'],
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(
                          DateFormat('dd MMM yyyy')
                              .format(DateTime.parse(tx['date'])),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(amount),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: errorColor),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget buildSmartInsights(ThemeData theme) {
    final insights = smartInsights;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radiusSmall,
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text('Smart Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          sizedBoxHeightMedium,
          ...insights.map((insight) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Model Classes (same as before)
class Budget {
  String name;
  double total;
  List<Expense> expenses;
  String id;
  bool isChecked;
  DateTime? checkedDate;
  DateTime createdDate;

  Budget({
    String? id,
    required this.name,
    required this.total,
    List<Expense>? expenses,
    this.isChecked = false,
    this.checkedDate,
    DateTime? createdDate,
  })  : expenses = expenses ?? [],
        id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdDate = createdDate ?? DateTime.now();

  double get totalSpent => expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get amountLeft => total - totalSpent;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'total': total,
        'expenses': expenses.map((e) => e.toMap()).toList(),
        'isChecked': isChecked,
        'checkedDate': checkedDate?.toIso8601String(),
        'createdDate': createdDate.toIso8601String(),
      };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: map['name'],
        total: (map['total'] as num).toDouble(),
        expenses: (map['expenses'] as List?)
                ?.map((e) => Expense.fromMap(e))
                .toList() ??
            [],
        isChecked: map['isChecked'] ?? map['checked'] ?? false,
        checkedDate: map['checkedDate'] != null
            ? DateTime.parse(map['checkedDate'])
            : null,
        createdDate: map['createdDate'] != null
            ? DateTime.parse(map['createdDate'])
            : DateTime.now(),
      );
}

class Expense {
  String name;
  double amount;
  String id;
  DateTime createdDate;

  Expense({
    String? id,
    required this.name,
    required this.amount,
    DateTime? createdDate,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdDate = createdDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'createdDate': createdDate.toIso8601String(),
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: map['name'],
        amount: (map['amount'] as num).toDouble(),
        createdDate: map['createdDate'] != null
            ? DateTime.parse(map['createdDate'])
            : DateTime.now(),
      );
}

class Saving {
  String name;
  double savedAmount;
  double targetAmount;
  DateTime deadline;
  bool achieved;
  String? iconCode;

  Saving({
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.deadline,
    this.achieved = false,
    this.iconCode,
  });

  double get balance => targetAmount - savedAmount;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'savedAmount': savedAmount,
      'targetAmount': targetAmount,
      'deadline': deadline.toIso8601String(),
      'achieved': achieved,
      'iconCode': iconCode,
    };
  }

  factory Saving.fromMap(Map<String, dynamic> map) {
    return Saving(
      name: map['name'] ?? 'Unnamed',
      savedAmount: map['savedAmount'] is String
          ? double.tryParse(map['savedAmount']) ?? 0.0
          : (map['savedAmount'] as num?)?.toDouble() ?? 0.0,
      targetAmount: map['targetAmount'] is String
          ? double.tryParse(map['targetAmount']) ?? 0.0
          : (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'])
          : DateTime.now().add(const Duration(days: 30)),
      achieved: map['achieved'] ?? false,
      iconCode: map['iconCode'],
    );
  }
}