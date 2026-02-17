import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Currency Formatter ───────────────────────────────────────────────────────
class CurrencyFormatter {
  static final NumberFormat _fmt = NumberFormat('#,##0', 'en_US');
  static String format(double amount) => 'Ksh ${_fmt.format(amount.round())}';
  static String compact(double amount) {
    if (amount >= 1000000)
      return 'Ksh ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'Ksh ${(amount / 1000).toStringAsFixed(1)}K';
    return format(amount);
  }
}

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
        if (customStartDate == null || customEndDate == null)
          return transactions;
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

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  double _amt(Map<String, dynamic> tx) =>
      double.tryParse(tx['amount'].toString()) ?? 0.0;
  double _fee(Map<String, dynamic> tx) =>
      double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;

  double get filteredIncome => filteredTransactions
      .where((tx) => tx['type'] == 'income')
      .fold(0.0, (s, tx) => s + _amt(tx));
  double get filteredExpenses => filteredTransactions
      .where((tx) => tx['type'] != 'income')
      .fold(0.0, (s, tx) => s + _amt(tx) + _fee(tx));
  double get filteredSavings => filteredTransactions
      .where(
        (tx) =>
            tx['type'] == 'savings_deduction' || tx['type'] == 'saving_deposit',
      )
      .fold(0.0, (s, tx) => s + _amt(tx));
  double get totalFeesPaid => filteredTransactions
      .where((tx) => tx['type'] != 'income')
      .fold(0.0, (s, tx) => s + _fee(tx));
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
      final cat = _categoriseTitle(tx['title'] ?? '');
      map[cat] = (map[cat] ?? 0) + _amt(tx) + _fee(tx);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  String _categoriseTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('food') ||
        lower.contains('lunch') ||
        lower.contains('dinner') ||
        lower.contains('breakfast') ||
        lower.contains('restaurant') ||
        lower.contains('snack'))
      return 'Food & Dining';
    if (lower.contains('transport') ||
        lower.contains('uber') ||
        lower.contains('taxi') ||
        lower.contains('fuel') ||
        lower.contains('matatu') ||
        lower.contains('bus'))
      return 'Transport';
    if (lower.contains('rent') ||
        lower.contains('house') ||
        lower.contains('electricity') ||
        lower.contains('water') ||
        lower.contains('utility'))
      return 'Housing';
    if (lower.contains('entertainment') ||
        lower.contains('movie') ||
        lower.contains('game') ||
        lower.contains('netflix') ||
        lower.contains('spotify'))
      return 'Entertainment';
    if (lower.contains('shopping') ||
        lower.contains('clothes') ||
        lower.contains('shoes'))
      return 'Shopping';
    if (lower.contains('health') ||
        lower.contains('doctor') ||
        lower.contains('pharmacy'))
      return 'Health';
    if (lower.contains('saved for') || lower.contains('savings'))
      return 'Savings';
    if (lower.contains('budget')) return 'Budgets';
    return 'Other';
  }

  // ─── Monthly data (last 6 months) ─────────────────────────────────────────────
  List<Map<String, dynamic>> get last6MonthsData {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0, 23, 59, 59);
      final label = DateFormat('MMM').format(month);
      double income = 0, expenses = 0, savings = 0;
      for (final tx in transactions) {
        final d = DateTime.parse(tx['date']);
        if (d.isBefore(month) || d.isAfter(monthEnd)) continue;
        if (tx['type'] == 'income') {
          income += _amt(tx);
        } else if (tx['type'] == 'savings_deduction' ||
            tx['type'] == 'saving_deposit') {
          savings += _amt(tx);
          expenses += _amt(tx) + _fee(tx);
        } else {
          expenses += _amt(tx) + _fee(tx);
        }
      }
      result.add({
        'label': label,
        'income': income,
        'expenses': expenses,
        'savings': savings,
      });
    }
    return result;
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
        if (d.isAfter(thisMonthStart))
          thisMonthInc += _amt(tx);
        else if (d.isAfter(lastMonthStart) && d.isBefore(lastMonthEnd))
          lastMonthInc += _amt(tx);
      } else {
        if (d.isAfter(thisMonthStart))
          thisMonthExp += _amt(tx) + _fee(tx);
        else if (d.isAfter(lastMonthStart) && d.isBefore(lastMonthEnd))
          lastMonthExp += _amt(tx) + _fee(tx);
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
          ..sort((a, b) => (_amt(b) + _fee(b)).compareTo(_amt(a) + _fee(a)));
    return exp.take(5).toList();
  }

  Color _budgetHealthColor(Budget b) {
    final pct = b.total > 0 ? (b.totalSpent / b.total) * 100 : 0.0;
    if (pct < 70) return brandGreen;
    if (pct < 90) return Colors.orange;
    return errorColor;
  }

  String _budgetHealthLabel(Budget b) {
    final pct = b.total > 0 ? (b.totalSpent / b.total) * 100 : 0.0;
    if (pct < 70) return 'Healthy';
    if (pct < 90) return 'Warning';
    return 'Over Budget';
  }

  // ─── Smart Insights ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get smartInsights {
    final list = <Map<String, dynamic>>[];
    final cmp = monthlyComparison;
    final change = cmp['change'] as double;

    // Month-over-month spending change
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

    // Savings rate
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

    // Projected month-end overspend
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

    // High category
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

    // Fee warning
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

    // Savings goals near deadline
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

    // Average daily spend
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
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            _pdfHeader(),
            pw.SizedBox(height: 20),
            _pdfSectionTitle('Financial Overview'),
            pw.SizedBox(height: 10),
            _pdfSummary(),
            pw.SizedBox(height: 20),
            _pdfSectionTitle('Income vs Expenses (6-month trend)'),
            pw.SizedBox(height: 10),
            _pdfBarChart(),
            pw.SizedBox(height: 20),
            if (expensesByCategory.isNotEmpty) ...[
              _pdfSectionTitle('Spending by Category'),
              pw.SizedBox(height: 10),
              _pdfCategoryChart(),
              pw.SizedBox(height: 20),
            ],
            _pdfSectionTitle('Monthly Comparison'),
            pw.SizedBox(height: 10),
            _pdfMonthlyComparison(),
            pw.SizedBox(height: 20),
            if (budgets.isNotEmpty) ...[
              _pdfSectionTitle('Budget Health'),
              pw.SizedBox(height: 10),
              _pdfBudgetHealth(),
              pw.SizedBox(height: 20),
            ],
            if (savings.isNotEmpty) ...[
              _pdfSectionTitle('Savings Goals'),
              pw.SizedBox(height: 10),
              _pdfSavingsGoals(),
              pw.SizedBox(height: 20),
            ],
            _pdfSectionTitle('Smart Insights'),
            pw.SizedBox(height: 10),
            _pdfInsights(),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.Center(
              child: pw.Text(
                'Generated by Penny Finance App',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'penny_analytics_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Penny Finance Analytics');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.share, color: Colors.white),
                SizedBox(width: 8),
                Text('Opening share…'),
              ],
            ),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e'), backgroundColor: errorColor),
        );
    } finally {
      if (mounted) setState(() => isGeneratingPDF = false);
    }
  }

  pw.Widget _pdfSectionTitle(String t) => pw.Text(
    t,
    style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
  );

  pw.Widget _pdfHeader() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Penny Finance Analytics Report',
        style: pw.TextStyle(
          fontSize: 22,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        'Period: $selectedFilter   Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    ],
  );

  pw.Widget _pdfSummary() => pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _pdfKpi('Income', filteredIncome, PdfColors.green),
            _pdfKpi('Expenses', filteredExpenses, PdfColors.red),
            _pdfKpi('Savings', filteredSavings, PdfColors.blue),
            _pdfKpi(
              'Net Balance',
              netBalance,
              netBalance >= 0 ? PdfColors.green : PdfColors.red,
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Savings Rate: ${savingsRate.toStringAsFixed(1)}%',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Expense Ratio: ${expenseRatio.toStringAsFixed(1)}%',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Avg Daily: ${CurrencyFormatter.format(avgDailySpend)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Fees: ${CurrencyFormatter.format(totalFeesPaid)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    ),
  );

  pw.Widget _pdfKpi(String label, double amount, PdfColor color) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 3),
      pw.Text(
        CurrencyFormatter.format(amount),
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );

  pw.Widget _pdfBarChart() {
    final data = last6MonthsData;
    final maxVal = data.fold(
      0.0,
      (m, d) => [
        m,
        d['income'] as double,
        d['expenses'] as double,
      ].reduce((a, b) => a > b ? a : b),
    );
    if (maxVal == 0)
      return pw.Text('No data', style: const pw.TextStyle(fontSize: 10));

    return pw.Container(
      height: 180,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: data.map((d) {
          final incH = 130 * ((d['income'] as double) / maxVal);
          final expH = 130 * ((d['expenses'] as double) / maxVal);
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 10,
                    height: incH,
                    color: PdfColors.green300,
                  ),
                  pw.SizedBox(width: 2),
                  pw.Container(
                    width: 10,
                    height: expH,
                    color: PdfColors.red300,
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                d['label'] as String,
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _pdfCategoryChart() {
    final cats = expensesByCategory;
    final total = cats.values.fold(0.0, (s, v) => s + v);
    if (total == 0)
      return pw.Text('No data', style: const pw.TextStyle(fontSize: 10));

    final pdfColors = [
      PdfColors.blue,
      PdfColors.orange,
      PdfColors.purple,
      PdfColors.green,
      PdfColors.red,
      PdfColors.teal,
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: cats.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final e = entry.value;
          final pct = total > 0 ? e.value / total * 100 : 0.0;
          final col = pdfColors[idx % pdfColors.length];
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 8,
                          height: 8,
                          decoration: pw.BoxDecoration(
                            color: col,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(e.key, style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Text(
                      '${pct.toStringAsFixed(0)}%  ${CurrencyFormatter.compact(e.value)}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Container(
                  height: 5,
                  width: pct * 3.5,
                  decoration: pw.BoxDecoration(
                    color: col,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  pw.Widget _pdfMonthlyComparison() {
    final cmp = monthlyComparison;
    final change = cmp['change'] as double;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _pdfKpi(
                'This Month Expenses',
                cmp['thisMonthExp'],
                PdfColors.red,
              ),
              _pdfKpi(
                'Last Month Expenses',
                cmp['lastMonthExp'],
                PdfColors.grey600,
              ),
              _pdfKpi(
                'This Month Income',
                cmp['thisMonthInc'],
                PdfColors.green,
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: change > 0 ? PdfColors.red50 : PdfColors.green50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              '${change.abs().toStringAsFixed(1)}% ${change > 0 ? 'increase' : 'decrease'} in spending vs last month',
              style: pw.TextStyle(
                fontSize: 10,
                color: change > 0 ? PdfColors.red : PdfColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfBudgetHealth() => pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children:
            ['Budget', 'Allocated', 'Spent', 'Remaining', 'Usage', 'Status']
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
      ...budgets.map((b) {
        final pct = b.total > 0 ? b.totalSpent / b.total * 100 : 0.0;
        final col = pct < 70
            ? PdfColors.green
            : pct < 90
            ? PdfColors.orange
            : PdfColors.red;
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(b.name, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                CurrencyFormatter.format(b.total),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                CurrencyFormatter.format(b.totalSpent),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                CurrencyFormatter.format(b.amountLeft),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                '${pct.toStringAsFixed(0)}%',
                style: pw.TextStyle(fontSize: 9, color: col),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                _budgetHealthLabel(b),
                style: pw.TextStyle(fontSize: 9, color: col),
              ),
            ),
          ],
        );
      }).toList(),
    ],
  );

  pw.Widget _pdfSavingsGoals() => pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children:
            [
                  'Goal',
                  'Target',
                  'Saved',
                  'Left',
                  'Progress',
                  'Deadline',
                  'Status',
                ]
                .map(
                  (h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
      ...savings.map((s) {
        final pct = s.progressPercent * 100;
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(s.name, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                CurrencyFormatter.format(s.targetAmount),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                CurrencyFormatter.format(s.savedAmount),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                CurrencyFormatter.format(s.balance.clamp(0, double.infinity)),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                '${pct.toStringAsFixed(0)}%',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                DateFormat('dd MMM yy').format(s.deadline),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                s.achieved ? 'Done ✓' : 'Active',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: s.achieved ? PdfColors.green : PdfColors.grey,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    ],
  );

  pw.Widget _pdfInsights() {
    final insights = smartInsights;
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: insights
            .map(
              (i) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      i['title'] as String,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      i['detail'] as String,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
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
            _buildFilterChips(),
            if (selectedFilter == 'Custom') ...[
              sizedBoxHeightSmall,
              _buildCustomDateRow(theme),
            ],
            sizedBoxHeightLarge,
            _buildSummaryHero(theme),
            sizedBoxHeightLarge,
            _buildMonthlyTrendChart(theme),
            sizedBoxHeightLarge,
            _buildCategoryPieSection(theme),
            sizedBoxHeightLarge,
            _buildBudgetHealth(theme),
            sizedBoxHeightLarge,
            _buildSavingsProgress(theme),
            sizedBoxHeightLarge,
            _buildTopExpenses(theme),
            sizedBoxHeightLarge,
            _buildMonthlyComparison(theme),
            sizedBoxHeightLarge,
            _buildPDFButton(theme),
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
            _buildFilterChips(),
            sizedBoxHeightLarge,
            // KPI strip at top of insights
            _buildKpiStrip(theme),
            sizedBoxHeightLarge,
            Text(
              'Personalised Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            sizedBoxHeightMedium,
            ...insights
                .map((insight) => _buildInsightCard(theme, insight))
                .toList(),
            sizedBoxHeightLarge,
            _buildSpendingCategoryTable(theme),
            sizedBoxHeightLarge,
            _buildDayOfWeekHeatmap(theme),
            sizedBoxHeightLarge,
          ],
        ),
      ),
    );
  }

  // ─── Filter chips ─────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    const filters = [
      'Today',
      'Last 7 Days',
      'This Month',
      'Last 3 Months',
      'This Year',
      'Custom',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomDateRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: customStartDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => customStartDate = d);
            },
            icon: const Icon(Icons.calendar_today, size: 15),
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
              final d = await showDatePicker(
                context: context,
                initialDate: customEndDate ?? DateTime.now(),
                firstDate: customStartDate ?? DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => customEndDate = d);
            },
            icon: const Icon(Icons.calendar_today, size: 15),
            label: Text(
              customEndDate == null
                  ? 'End Date'
                  : DateFormat('dd MMM').format(customEndDate!),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Summary Hero (NEW design) ───────────────────────────────────────────────
  Widget _buildSummaryHero(ThemeData theme) {
    final isPositive = netBalance >= 0;

    return Column(
      children: [
        // Big gradient net balance card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPositive
                  ? [accentColor, accentColor.withOpacity(0.7)]
                  : [errorColor, errorColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isPositive ? accentColor : errorColor).withOpacity(0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Net Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      selectedFilter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(netBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),
              // Income/Expenses/Savings three-up
              IntrinsicHeight(
                child: Row(
                  children: [
                    _heroStat(
                      'Income',
                      filteredIncome,
                      Icons.arrow_circle_down_rounded,
                      Colors.greenAccent.shade200,
                    ),
                    VerticalDivider(
                      color: Colors.white.withOpacity(0.2),
                      thickness: 1,
                      width: 20,
                    ),
                    _heroStat(
                      'Expenses',
                      filteredExpenses,
                      Icons.arrow_circle_up_rounded,
                      Colors.red.shade200,
                    ),
                    VerticalDivider(
                      color: Colors.white.withOpacity(0.2),
                      thickness: 1,
                      width: 20,
                    ),
                    _heroStat(
                      'Savings',
                      filteredSavings,
                      Icons.savings,
                      Colors.lightBlue.shade200,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Progress bars
              _ratioBar(
                'Expense ratio',
                expenseRatio / 100,
                expenseRatio > 90
                    ? Colors.red.shade300
                    : expenseRatio > 70
                    ? Colors.orange.shade300
                    : Colors.green.shade300,
                '${expenseRatio.toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 6),
              _ratioBar(
                'Savings rate',
                savingsRate / 100,
                savingsRate >= 20
                    ? Colors.greenAccent.shade200
                    : Colors.orange.shade300,
                '${savingsRate.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ),
        sizedBoxHeightMedium,
        // KPI row
        Row(
          children: [
            _kpiCard(
              theme,
              'Avg/Day',
              CurrencyFormatter.compact(avgDailySpend),
              Icons.today,
              Colors.purple,
            ),
            const SizedBox(width: 8),
            _kpiCard(
              theme,
              'Fees',
              CurrencyFormatter.compact(totalFeesPaid),
              Icons.receipt_outlined,
              Colors.orange,
            ),
            const SizedBox(width: 8),
            _kpiCard(
              theme,
              'Transactions',
              '${filteredTransactions.length}',
              Icons.receipt_long,
              accentColor,
            ),
            const SizedBox(width: 8),
            _kpiCard(
              theme,
              'Goals Done',
              '${savings.where((s) => s.achieved).length}/${savings.length}',
              Icons.flag_rounded,
              brandGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroStat(String label, double amount, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            CurrencyFormatter.compact(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratioBar(String label, double value, Color color, String badge) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
            Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: Colors.white.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Monthly Trend Chart (fl_chart BarChart — last 6 months) ─────────────────
  Widget _buildMonthlyTrendChart(ThemeData theme) {
    final data = last6MonthsData;
    final maxVal = data.fold(
      0.0,
      (m, d) => [
        m,
        d['income'] as double,
        d['expenses'] as double,
      ].reduce((a, b) => a > b ? a : b),
    );

    return _card(
      theme,
      '6-Month Trend',
      Icons.show_chart,
      null,
      Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(brandGreen, 'Income'),
              const SizedBox(width: 16),
              _legendDot(errorColor, 'Expenses'),
              const SizedBox(width: 16),
              _legendDot(accentColor, 'Savings'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: maxVal == 0
                ? Center(
                    child: Text(
                      'No data',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxVal * 1.25,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.black87,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final labels = ['Income', 'Expenses', 'Savings'];
                            return BarTooltipItem(
                              '${labels[rodIndex]}\n${CurrencyFormatter.compact(rod.toY)}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) => Text(
                              data[val.toInt()]['label'] as String,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (val, meta) => Text(
                              CurrencyFormatter.compact(val),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                        getDrawingHorizontalLine: (val) =>
                            FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.asMap().entries.map((entry) {
                        final i = entry.key;
                        final d = entry.value;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: d['income'] as double,
                              color: brandGreen,
                              width: 9,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: d['expenses'] as double,
                              color: errorColor,
                              width: 9,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: d['savings'] as double,
                              color: accentColor,
                              width: 9,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );

  // ─── Pie chart + category list ────────────────────────────────────────────────
  Widget _buildCategoryPieSection(ThemeData theme) {
    final cats = expensesByCategory;
    if (cats.isEmpty) return const SizedBox.shrink();

    final colors = [
      accentColor,
      brandGreen,
      Colors.orange,
      Colors.purple,
      errorColor,
      Colors.teal,
      Colors.pink,
    ];
    final total = cats.values.fold(0.0, (s, v) => s + v);

    int ci = 0;
    final sections = cats.entries.map((e) {
      final color = colors[ci++ % colors.length];
      final pct = total > 0 ? (e.value / total) : 0.0;
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: pct > 0.06 ? '${(pct * 100).toStringAsFixed(0)}%' : '',
        radius: 58,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return _card(
      theme,
      'Expense Distribution',
      Icons.pie_chart_outline,
      null,
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cats.entries.toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  final color = colors[idx % colors.length];
                  final pct = total > 0 ? (e.value / total * 100) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${pct.toStringAsFixed(0)}%  ${CurrencyFormatter.compact(e.value)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  // ─── Budget Health ────────────────────────────────────────────────────────────
  Widget _buildBudgetHealth(ThemeData theme) {
    if (budgets.isEmpty) return const SizedBox.shrink();
    return _card(
      theme,
      'Budget Health',
      Icons.account_balance_wallet_outlined,
      '${budgets.length} budgets',
      Column(
        children: budgets.map((b) {
          final color = _budgetHealthColor(b);
          final label = _budgetHealthLabel(b);
          final progress = b.total > 0
              ? (b.totalSpent / b.total).clamp(0.0, 1.0)
              : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${CurrencyFormatter.compact(b.totalSpent)} spent',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% of ${CurrencyFormatter.compact(b.total)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Savings Progress ────────────────────────────────────────────────────────
  Widget _buildSavingsProgress(ThemeData theme) {
    if (savings.isEmpty) return const SizedBox.shrink();
    final achieved = savings.where((s) => s.achieved).length;

    return _card(
      theme,
      'Savings Goals',
      Icons.savings_outlined,
      '$achieved/${savings.length} achieved',
      Column(
        children: savings.map((s) {
          final color = s.achieved
              ? brandGreen
              : s.deadline.isBefore(DateTime.now())
              ? errorColor
              : accentColor;
          final daysLeft = s.deadline.difference(DateTime.now()).inDays;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s.achieved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: brandGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: brandGreen),
                        ),
                        child: const Text(
                          'Achieved 🎉',
                          style: TextStyle(
                            fontSize: 10,
                            color: brandGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Text(
                        daysLeft < 0
                            ? '${daysLeft.abs()}d overdue'
                            : '$daysLeft days left',
                        style: TextStyle(
                          fontSize: 11,
                          color: daysLeft < 0
                              ? errorColor
                              : Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${CurrencyFormatter.compact(s.savedAmount)} saved',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${(s.progressPercent * 100).toStringAsFixed(0)}% of ${CurrencyFormatter.compact(s.targetAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: s.progressPercent,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Remaining: ${CurrencyFormatter.format(s.balance.clamp(0, double.infinity))}  ·  Due: ${DateFormat('dd MMM yyyy').format(s.deadline)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Top Expenses ─────────────────────────────────────────────────────────────
  Widget _buildTopExpenses(ThemeData theme) {
    final top = topExpenses;
    if (top.isEmpty) return const SizedBox.shrink();
    final maxAmt = _amt(top.first) + _fee(top.first);
    const medals = ['🥇', '🥈', '🥉', '4th', '5th'];

    return _card(
      theme,
      'Top 5 Expenses',
      Icons.leaderboard_outlined,
      null,
      Column(
        children: top.asMap().entries.map((entry) {
          final idx = entry.key;
          final tx = entry.value;
          final amt = _amt(tx) + _fee(tx);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(medals[idx], style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxAmt > 0 ? amt / maxAmt : 0,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation(
                            idx == 0
                                ? Colors.amber.shade500
                                : accentColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  CurrencyFormatter.compact(amt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: errorColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Monthly Comparison ──────────────────────────────────────────────────────
  Widget _buildMonthlyComparison(ThemeData theme) {
    final cmp = monthlyComparison;
    final change = cmp['change'] as double;
    final isUp = change > 0;

    return _card(
      theme,
      'Month vs Last Month',
      Icons.compare_arrows_rounded,
      null,
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _comparisonStat(
                  theme,
                  'This Month',
                  cmp['thisMonthExp'],
                  'Expenses',
                  errorColor,
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey.shade100),
              Expanded(
                child: _comparisonStat(
                  theme,
                  'Last Month',
                  cmp['lastMonthExp'],
                  'Expenses',
                  Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _comparisonStat(
                  theme,
                  'This Month',
                  cmp['thisMonthInc'],
                  'Income',
                  brandGreen,
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey.shade100),
              Expanded(
                child: _comparisonStat(
                  theme,
                  'Last Month',
                  cmp['lastMonthInc'],
                  'Income',
                  Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isUp ? errorColor : brandGreen).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isUp ? Icons.trending_up : Icons.trending_down,
                  color: isUp ? errorColor : brandGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${change.abs().toStringAsFixed(1)}% ${isUp ? 'higher' : 'lower'} spending vs last month',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUp ? errorColor : brandGreen,
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

  Widget _comparisonStat(
    ThemeData theme,
    String period,
    double amount,
    String label,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.compact(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ─── KPI Strip (Insights Tab) ────────────────────────────────────────────────
  Widget _buildKpiStrip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.08),
            accentColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stripStat(
                'Net Balance',
                CurrencyFormatter.compact(netBalance),
                netBalance >= 0 ? brandGreen : errorColor,
              ),
              _vDivider(),
              _stripStat(
                'Savings Rate',
                '${savingsRate.toStringAsFixed(1)}%',
                savingsRate >= 20 ? brandGreen : Colors.orange,
              ),
              _vDivider(),
              _stripStat(
                'Expense Ratio',
                '${expenseRatio.toStringAsFixed(1)}%',
                expenseRatio > 90
                    ? errorColor
                    : expenseRatio > 70
                    ? Colors.orange
                    : brandGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stripStat(
                'Avg Daily',
                CurrencyFormatter.compact(avgDailySpend),
                accentColor,
              ),
              _vDivider(),
              _stripStat(
                'Fees Paid',
                CurrencyFormatter.compact(totalFeesPaid),
                Colors.orange,
              ),
              _vDivider(),
              _stripStat(
                'Projected',
                CurrencyFormatter.compact(projectedMonthEndSpend),
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stripStat(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
    ],
  );

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: Colors.grey.shade200);

  // ─── Insight Card ────────────────────────────────────────────────────────────
  Widget _buildInsightCard(ThemeData theme, Map<String, dynamic> insight) {
    final color = insight['color'] as Color;
    final good = insight['good'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(insight['icon'] as IconData, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insight['detail'] as String,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(
            good ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
            size: 18,
          ),
        ],
      ),
    );
  }

  // ─── Spending Category Table ──────────────────────────────────────────────────
  Widget _buildSpendingCategoryTable(ThemeData theme) {
    final cats = expensesByCategory;
    if (cats.isEmpty) return const SizedBox.shrink();
    final total = cats.values.fold(0.0, (s, v) => s + v);
    final colors = [
      accentColor,
      brandGreen,
      Colors.orange,
      Colors.purple,
      errorColor,
      Colors.teal,
      Colors.pink,
    ];

    return _card(
      theme,
      'Spending Breakdown',
      Icons.category_outlined,
      null,
      Column(
        children: cats.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final e = entry.value;
          final pct = total > 0 ? e.value / total : 0.0;
          final color = colors[idx % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.compact(e.value),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Day of week heatmap ──────────────────────────────────────────────────────
  Widget _buildDayOfWeekHeatmap(ThemeData theme) {
    final counts = List.filled(7, 0);
    for (final tx in filteredTransactions) {
      counts[(DateTime.parse(tx['date']).weekday - 1) % 7]++;
    }
    final maxCount = counts.fold(0, (a, b) => a > b ? a : b);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return _card(
      theme,
      'Activity by Day',
      Icons.calendar_view_week_outlined,
      null,
      Column(
        children: [
          Row(
            children: List.generate(7, (i) {
              final ratio = maxCount > 0 ? counts[i] / maxCount : 0.0;
              final isMax = counts[i] == maxCount && maxCount > 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Text(
                        '${counts[i]}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMax ? accentColor : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 60,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation(
                            isMax ? accentColor : accentColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        days[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: isMax ? accentColor : Colors.grey.shade600,
                          fontWeight: isMax
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (isMax)
                        Text('🔥', style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Total ${filteredTransactions.length} transactions in this period',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PDF button ───────────────────────────────────────────────────────────────
  Widget _buildPDFButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isGeneratingPDF ? null : generatePDF,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        icon: isGeneratingPDF
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.share, size: 22),
        label: Text(
          isGeneratingPDF ? 'Generating Analytics PDF…' : 'Share Analytics PDF',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ─── Reusable card ────────────────────────────────────────────────────────────
  Widget _card(
    ThemeData theme,
    String title,
    IconData icon,
    String? badge,
    Widget child,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (badge != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─── Model Classes ─────────────────────────────────────────────────────────────
class Budget {
  String id, name;
  double total;
  List<Expense> expenses;
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
  }) : expenses = expenses ?? [],
       id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdDate = createdDate ?? DateTime.now();

  double get totalSpent => expenses.fold(0.0, (s, e) => s + e.amount);
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
    expenses:
        (map['expenses'] as List?)?.map((e) => Expense.fromMap(e)).toList() ??
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
  String id, name;
  double amount;
  DateTime createdDate;

  Expense({
    String? id,
    required this.name,
    required this.amount,
    DateTime? createdDate,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
  double savedAmount, targetAmount;
  DateTime deadline, lastUpdated;
  bool achieved;
  List<dynamic> transactions;

  Saving({
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.deadline,
    this.achieved = false,
    DateTime? lastUpdated,
    List<dynamic>? transactions,
  }) : lastUpdated = lastUpdated ?? DateTime.now(),
       transactions = transactions ?? [];

  double get balance => targetAmount - savedAmount;
  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() => {
    'name': name,
    'savedAmount': savedAmount,
    'targetAmount': targetAmount,
    'deadline': deadline.toIso8601String(),
    'achieved': achieved,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory Saving.fromMap(Map<String, dynamic> map) => Saving(
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
    lastUpdated: map['lastUpdated'] != null
        ? DateTime.parse(map['lastUpdated'])
        : DateTime.now(),
    transactions: (map['transactions'] as List?) ?? [],
  );
}
