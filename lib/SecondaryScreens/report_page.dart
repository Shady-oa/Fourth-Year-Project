import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
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
    if (amount >= 1000000) {
      return 'Ksh ${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return 'Ksh ${(amount / 1000).toStringAsFixed(1)}K';
    return format(amount);
  }
}

// ─── Date Preset ─────────────────────────────────────────────────────────────
enum DatePreset {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
  custom,
}

extension DatePresetLabel on DatePreset {
  String get label {
    switch (this) {
      case DatePreset.today:
        return 'Today';
      case DatePreset.thisWeek:
        return 'This Week';
      case DatePreset.thisMonth:
        return 'This Month';
      case DatePreset.lastMonth:
        return 'Last Month';
      case DatePreset.last3Months:
        return '3 Months';
      case DatePreset.thisYear:
        return 'This Year';
      case DatePreset.custom:
        return 'Custom';
    }
  }
}

// ─── Daily total helper ────────────────────────────────────────────────────────
class _DailyTotal {
  final String day;
  final double amount;
  const _DailyTotal(this.day, this.amount);
}

// ─── Report Page ─────────────────────────────────────────────────────────────
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
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

  // ─── Date preset ─────────────────────────────────────────────────────────────
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

  // ─── Aggregates ─────────────────────────────────────────────────────────────
  double _amt(Map<String, dynamic> tx) =>
      double.tryParse(tx['amount'].toString()) ?? 0.0;
  double _fee(Map<String, dynamic> tx) =>
      double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;

  double get filteredIncome => filteredTransactions
      .where((tx) => tx['type'] == 'income')
      .fold(0.0, (s, tx) => s + _amt(tx));
  double get filteredExpenses => filteredTransactions
      .where((tx) => tx['type'] != 'income')
      .fold(0.0, (s, tx) {
        final type = (tx['type'] ?? '') as String;
        // For savings_deduction/saving_deposit: 'amount' already = principal+fee.
        // Do NOT add _fee(tx) again to avoid double-counting.
        if (type == 'savings_deduction' || type == 'saving_deposit') {
          return s + _amt(tx);
        }
        return s + _amt(tx) + _fee(tx);
      });
  // filteredSavings: principal only (no fee) for the statistics card display.
  double get filteredSavings => filteredTransactions
      .where(
        (tx) =>
            tx['type'] == 'savings_deduction' || tx['type'] == 'saving_deposit',
      )
      .fold(
        0.0,
        (s, tx) => (s + _amt(tx) - _fee(tx)).clamp(0.0, double.infinity),
      );
  double get totalFeesPaid => filteredTransactions
      .where((tx) => tx['type'] != 'income')
      .fold(0.0, (s, tx) => s + _fee(tx));
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
        .where((tx) => tx['type'] != 'income')
        .toList();
    if (exp.isEmpty) return null;
    exp.sort((a, b) => (_amt(b) + _fee(b)).compareTo(_amt(a) + _fee(a)));
    return exp.first;
  }

  Map<String, double> get spendingByCategory {
    final map = <String, double>{};
    for (final tx in filteredTransactions) {
      if (tx['type'] == 'income') continue;
      final type = (tx['type'] ?? '') as String;
      final label = _getTypeLabel(tx['type']);
      // For savings: amount already = principal+fee; do NOT add _fee again.
      if (type == 'savings_deduction' || type == 'saving_deposit') {
        map[label] = (map[label] ?? 0) + _amt(tx);
      } else {
        map[label] = (map[label] ?? 0) + _amt(tx) + _fee(tx);
      }
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  List<_DailyTotal> get dailySpending {
    if (startDate == null || endDate == null) return [];
    final map = <String, double>{};
    for (final tx in filteredTransactions) {
      if (tx['type'] == 'income') continue;
      final type = (tx['type'] ?? '') as String;
      final key = DateFormat('dd/MM').format(DateTime.parse(tx['date']));
      // For savings: amount already = principal+fee; do NOT add _fee again.
      if (type == 'savings_deduction' || type == 'saving_deposit') {
        map[key] = (map[key] ?? 0) + _amt(tx);
      } else {
        map[key] = (map[key] ?? 0) + _amt(tx) + _fee(tx);
      }
    }
    final days = endDate!.difference(startDate!).inDays + 1;
    final result = <_DailyTotal>[];
    for (var i = 0; i < days && i < 31; i++) {
      final d = startDate!.add(Duration(days: i));
      final key = DateFormat('dd/MM').format(d);
      result.add(_DailyTotal(key, map[key] ?? 0));
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
        filteredTransactions.where((tx) => tx['type'] != 'income').toList()
          ..sort((a, b) => (_amt(b) + _fee(b)).compareTo(_amt(a) + _fee(a)));
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
        prior += _amt(tx) + _fee(tx);
      }
    }
    return {'prior': prior, 'current': filteredExpenses};
  }

  // ─── PDF Export ────────────────────────────────────────────────────────────
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
            _pdfSectionTitle('Financial Summary'),
            pw.SizedBox(height: 10),
            _pdfSummary(),
            pw.SizedBox(height: 20),
            _pdfSectionTitle('Spending Breakdown'),
            pw.SizedBox(height: 10),
            _pdfCategoryBreakdown(),
            if (budgets.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _pdfSectionTitle('Budget Utilisation'),
              pw.SizedBox(height: 10),
              _pdfBudgetsTable(),
            ],
            if (savings.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _pdfSectionTitle('Savings Goals'),
              pw.SizedBox(height: 10),
              _pdfSavingsTable(),
            ],
            pw.SizedBox(height: 20),
            _pdfSectionTitle('Transaction Details'),
            pw.SizedBox(height: 10),
            _pdfTransactionTable(),
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
          'penny_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Penny Finance Report');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.share, color: Colors.white),
                SizedBox(width: 8),
                Text('Opening share dialog...'),
              ],
            ),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e'), backgroundColor: errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => isGeneratingPDF = false);
    }
  }

  // ─── PDF helpers ─────────────────────────────────────────────────────────────
  pw.Widget _pdfSectionTitle(String t) => pw.Text(
    t,
    style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
  );

  pw.Widget _pdfHeader() => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Penny Finance Report',
        style: pw.TextStyle(
          fontSize: 22,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        'Period: ${DateFormat('dd MMM yyyy').format(startDate!)} – ${DateFormat('dd MMM yyyy').format(endDate!)}',
        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
      ),
      pw.Text(
        'Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
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
            _pdfKpi('Total Income', filteredIncome, PdfColors.green),
            _pdfKpi('Total Expenses', filteredExpenses, PdfColors.red),
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
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Transactions: ${filteredTransactions.length}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Avg Daily Spend: ${CurrencyFormatter.format(avgDailySpend)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Total Fees: ${CurrencyFormatter.format(totalFeesPaid)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              'Savings Rate: ${savingsRate.toStringAsFixed(1)}%',
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

  pw.Widget _pdfCategoryBreakdown() {
    final cats = spendingByCategory;
    if (cats.isEmpty) {
      return pw.Text(
        'No spending data',
        style: const pw.TextStyle(fontSize: 10),
      );
    }
    final total = cats.values.fold(0.0, (s, v) => s + v);
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: cats.entries.map((e) {
          final pct = total > 0 ? (e.value / total * 100) : 0.0;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(e.key, style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      '${pct.toStringAsFixed(0)}%  ${CurrencyFormatter.format(e.value)}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Container(
                  height: 6,
                  width: pct * 4,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue,
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

  pw.Widget _pdfBudgetsTable() => pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: ['Budget', 'Total', 'Spent', 'Remaining', 'Usage']
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
        final pct = b.total > 0 ? (b.totalSpent / b.total * 100) : 0.0;
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(b.name, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                CurrencyFormatter.format(b.total),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                CurrencyFormatter.format(b.totalSpent),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                CurrencyFormatter.format(b.amountLeft),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${pct.toStringAsFixed(0)}%',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        );
      }),
    ],
  );

  pw.Widget _pdfSavingsTable() => pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey300),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children:
            ['Goal', 'Target', 'Saved', 'Remaining', 'Progress', 'Deadline']
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
        final pct = s.targetAmount > 0
            ? (s.savedAmount / s.targetAmount * 100).clamp(0.0, 100.0)
            : 0.0;
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(s.name, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                CurrencyFormatter.format(s.targetAmount),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                CurrencyFormatter.format(s.savedAmount),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                CurrencyFormatter.format(s.balance),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                '${pct.toStringAsFixed(0)}%',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                DateFormat('dd MMM yyyy').format(s.deadline),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        );
      }),
    ],
  );

  pw.Widget _pdfTransactionTable() {
    final txList = filteredTransactions.take(100).toList();
    if (txList.isEmpty) {
      return pw.Text(
        'No transactions found',
        style: const pw.TextStyle(fontSize: 10),
      );
    }
    return pw.Column(
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: const {
            0: pw.FractionColumnWidth(0.15),
            1: pw.FractionColumnWidth(0.35),
            2: pw.FractionColumnWidth(0.15),
            3: pw.FractionColumnWidth(0.15),
            4: pw.FractionColumnWidth(0.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: ['Date', 'Description', 'Type', 'Fee', 'Amount']
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
            ...txList.map((tx) {
              final d = DateTime.parse(tx['date']);
              final amt = _amt(tx);
              final fee = _fee(tx);
              final isIncome = tx['type'] == 'income';
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      DateFormat('dd/MM/yy').format(d),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      tx['title'] ?? '',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      _getTypeLabel(tx['type']),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      fee > 0 ? CurrencyFormatter.format(fee) : '-',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(isIncome ? amt : amt + fee)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: isIncome ? PdfColors.green : PdfColors.red,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        if (filteredTransactions.length > 100)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              'Showing first 100 of ${filteredTransactions.length} transactions.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _getTypeLabel(String? type) {
    switch (type) {
      case 'income':
        return 'Income';
      case 'budget_finalized':
      case 'budget_expense':
        return 'Budget';
      case 'savings_deduction':
      case 'saving_deposit':
        return 'Savings';
      case 'expense':
        return 'Expense';
      default:
        return 'Other';
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
        title: const CustomHeader(headerName: 'Report'),
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
            tooltip: 'Share PDF',
          ),
        ],
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
    return RefreshIndicator(
      onRefresh: loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: paddingAllMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDatePresets(),
            if (selectedPreset == DatePreset.custom) ...[
              sizedBoxHeightSmall,
              _buildCustomDateRow(theme),
            ],
            sizedBoxHeightSmall,
            _buildFiltersRow(theme),
            sizedBoxHeightLarge,
            _collapsible(
              'Summary',
              _summaryExpanded,
              () => setState(() => _summaryExpanded = !_summaryExpanded),
              _buildSummarySection(theme),
            ),
            sizedBoxHeightMedium,
            _collapsible(
              'Key Insights',
              _insightsExpanded,
              () => setState(() => _insightsExpanded = !_insightsExpanded),
              _buildKeyInsightsSection(theme),
            ),
            sizedBoxHeightMedium,
            _collapsible(
              'Budget Status',
              _budgetsExpanded,
              () => setState(() => _budgetsExpanded = !_budgetsExpanded),
              _buildBudgetsSection(theme),
            ),
            sizedBoxHeightMedium,
            _collapsible(
              'Savings Goals',
              _savingsExpanded,
              () => setState(() => _savingsExpanded = !_savingsExpanded),
              _buildSavingsSection(theme),
            ),
            sizedBoxHeightLarge,
            _buildExportButton(theme),
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
            _buildDatePresets(),
            sizedBoxHeightLarge,
            _buildSpendingCategoryChart(theme),
            sizedBoxHeightLarge,
            _buildDailySpendingBars(theme),
            sizedBoxHeightLarge,
            _buildDayOfWeekActivity(theme),
            sizedBoxHeightLarge,
            _buildTopExpenses(theme),
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
            _buildDatePresets(),
            if (selectedPreset == DatePreset.custom) ...[
              sizedBoxHeightSmall,
              _buildCustomDateRow(theme),
            ],
            sizedBoxHeightSmall,
            _buildFiltersRow(theme),
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
              _buildEmptyState(
                theme,
                'No transactions found',
                'Try adjusting your filters or date range',
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
                    ...entry.value.map((tx) => buildTransactionCard(tx, theme)),
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

  // ─── Date Presets Row ────────────────────────────────────────────────────────
  Widget _buildDatePresets() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DatePreset.values.map((preset) {
          final isSelected = selectedPreset == preset;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (preset == DatePreset.custom) {
                  setState(() => selectedPreset = DatePreset.custom);
                } else {
                  _applyPreset(preset);
                }
              },
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
                  preset.label,
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
              final date = await showDatePicker(
                context: context,
                initialDate: startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => startDate = date);
            },
            icon: const Icon(Icons.calendar_today, size: 15),
            label: Text(
              startDate == null
                  ? 'Start Date'
                  : DateFormat('dd MMM').format(startDate!),
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
                initialDate: endDate ?? DateTime.now(),
                firstDate: startDate ?? DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => endDate = date);
            },
            icon: const Icon(Icons.calendar_today, size: 15),
            label: Text(
              endDate == null
                  ? 'End Date'
                  : DateFormat('dd MMM').format(endDate!),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(theme, 'Type', selectedType, [
            'All',
            'Income',
            'Expense',
            'Savings',
          ], (v) => setState(() => selectedType = v)),
        ),
        if (budgets.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildDropdown(theme, 'Budget', selectedBudget, [
              'All',
              ...budgets.map((b) => b.name),
            ], (v) => setState(() => selectedBudget = v)),
          ),
        ],
        if (savings.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildDropdown(theme, 'Goal', selectedSaving, [
              'All',
              ...savings.map((s) => s.name),
            ], (v) => setState(() => selectedSaving = v)),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown(
    ThemeData theme,
    String hint,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── Summary Section ────────────────────────────────────────────────────────
  Widget _buildSummarySection(ThemeData theme) {
    final comparison = priorPeriodExpenses;
    final priorExp = comparison['prior'] ?? 0;
    final changeAmt = filteredExpenses - priorExp;
    final changePct = priorExp > 0 ? (changeAmt / priorExp * 100) : 0.0;
    final isUp = changeAmt > 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.25),
                blurRadius: 16,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(netBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUp ? Icons.trending_up : Icons.trending_down,
                          color: isUp
                              ? Colors.red.shade200
                              : Colors.green.shade200,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${changePct.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isUp
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _summaryStatCard(
                    'Income',
                    filteredIncome,
                    Icons.arrow_circle_down_rounded,
                    brandGreen,
                  ),
                  const SizedBox(width: 8),
                  _summaryStatCard(
                    'Expenses',
                    filteredExpenses,
                    Icons.arrow_circle_up_rounded,
                    errorColor,
                  ),
                  const SizedBox(width: 8),
                  _summaryStatCard(
                    'Savings',
                    filteredSavings,
                    Icons.savings,
                    Colors.lightBlue,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filteredIncome > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Expense ratio',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      '${expenseRatio.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (expenseRatio / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(
                      expenseRatio > 90
                          ? Colors.red.shade300
                          : expenseRatio > 70
                          ? Colors.orange.shade300
                          : Colors.green.shade300,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        sizedBoxHeightMedium,
        Row(
          children: [
            _miniStatCard(
              theme,
              'Avg/Day',
              CurrencyFormatter.compact(avgDailySpend),
              Icons.today,
              Colors.purple,
            ),
            const SizedBox(width: 8),
            _miniStatCard(
              theme,
              'Fees Paid',
              CurrencyFormatter.compact(totalFeesPaid),
              Icons.percent,
              Colors.orange,
            ),
            const SizedBox(width: 8),
            _miniStatCard(
              theme,
              'Transactions',
              '${filteredTransactions.length}',
              Icons.receipt,
              accentColor,
            ),
            const SizedBox(width: 8),
            _miniStatCard(
              theme,
              'Savings Rate',
              '${savingsRate.toStringAsFixed(1)}%',
              Icons.savings_outlined,
              brandGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryStatCard(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.compact(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(
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

  // ─── Key Insights Section ───────────────────────────────────────────────────
  Widget _buildKeyInsightsSection(ThemeData theme) {
    final insights = <Map<String, dynamic>>[];
    final comparison = priorPeriodExpenses;
    final prior = comparison['prior'] ?? 0.0;
    if (prior > 0) {
      final changePct = ((filteredExpenses - prior) / prior) * 100;
      insights.add({
        'icon': changePct > 0 ? Icons.trending_up : Icons.trending_down,
        'color': changePct > 0 ? errorColor : brandGreen,
        'title': changePct > 0 ? 'Spending Increased' : 'Spending Decreased',
        'subtitle': '${changePct.abs().toStringAsFixed(1)}% vs prior period',
      });
    }
    if (selectedPreset == DatePreset.thisMonth) {
      insights.add({
        'icon': Icons.auto_graph,
        'color': Colors.purple,
        'title': 'Projected Month-End Spend',
        'subtitle': CurrencyFormatter.format(projectedMonthEndSpend),
      });
    }
    final biggest = biggestExpense;
    if (biggest != null) {
      insights.add({
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orange,
        'title': 'Largest Expense',
        'subtitle':
            '${biggest['title']} · ${CurrencyFormatter.format(_amt(biggest) + _fee(biggest))}',
      });
    }
    for (final s in savings) {
      if (!s.achieved && s.progressPercent > 0.8) {
        insights.add({
          'icon': Icons.flag_rounded,
          'color': brandGreen,
          'title':
              '${(s.progressPercent * 100).toStringAsFixed(0)}% to goal: ${s.name}',
          'subtitle':
              '${CurrencyFormatter.format(s.savedAmount)} / ${CurrencyFormatter.format(s.targetAmount)}',
        });
      }
    }
    if (totalFeesPaid > filteredExpenses * 0.05) {
      insights.add({
        'icon': Icons.receipt_outlined,
        'color': Colors.orange,
        'title': 'High Transaction Fees',
        'subtitle':
            '${CurrencyFormatter.format(totalFeesPaid)} in fees (${(totalFeesPaid / filteredExpenses * 100).toStringAsFixed(1)}% of spend)',
      });
    }
    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.lightbulb_outline,
        'color': accentColor,
        'title': 'Keep going!',
        'subtitle': 'Add more transactions to unlock insights.',
      });
    }

    return Column(
      children: insights.map((insight) {
        final color = insight['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  insight['icon'] as IconData,
                  color: color,
                  size: 20,
                ),
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
                    const SizedBox(height: 2),
                    Text(
                      insight['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Budgets Section ─────────────────────────────────────────────────────────
  Widget _buildBudgetsSection(ThemeData theme) {
    if (budgets.isEmpty) {
      return _buildEmptyState(
        theme,
        'No budgets',
        'Create budgets to track your spending',
      );
    }

    return Column(
      children: budgets.map((b) {
        final progress = b.total > 0
            ? (b.totalSpent / b.total).clamp(0.0, 1.0)
            : 0.0;
        final isOver = b.totalSpent > b.total;
        final color = isOver
            ? errorColor
            : progress > 0.8
            ? Colors.orange
            : brandGreen;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: color,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (b.isChecked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: brandGreen),
                      ),
                      child: const Text(
                        'Finalized',
                        style: TextStyle(
                          fontSize: 10,
                          color: brandGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${CurrencyFormatter.compact(b.totalSpent)} spent',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% of ${CurrencyFormatter.compact(b.total)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              if (isOver) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: errorColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Over by ${CurrencyFormatter.format(b.totalSpent - b.total)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Savings Section ─────────────────────────────────────────────────────────
  Widget _buildSavingsSection(ThemeData theme) {
    if (savings.isEmpty) {
      return _buildEmptyState(
        theme,
        'No savings goals',
        'Create goals to start saving',
      );
    }

    return Column(
      children: savings.map((s) {
        final progress = s.progressPercent;
        final daysLeft = s.deadline.difference(DateTime.now()).inDays;
        final isOverdue = daysLeft < 0;
        final isAchieved = s.achieved;
        final color = isAchieved
            ? brandGreen
            : isOverdue
            ? errorColor
            : accentColor;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverdue
                  ? errorColor.withOpacity(0.3)
                  : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.savings, color: color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAchieved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: brandGreen),
                      ),
                      child: const Text(
                        'Achieved! 🎉',
                        style: TextStyle(
                          fontSize: 10,
                          color: brandGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      isOverdue
                          ? '${daysLeft.abs()}d overdue'
                          : '$daysLeft days left',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? errorColor : Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${CurrencyFormatter.compact(s.savedAmount)} saved',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% of ${CurrencyFormatter.compact(s.targetAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: ${CurrencyFormatter.format(s.balance.clamp(0, double.infinity))}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    'Due: ${DateFormat('dd MMM yyyy').format(s.deadline)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Spending Category Chart ─────────────────────────────────────────────────
  Widget _buildSpendingCategoryChart(ThemeData theme) {
    final cats = spendingByCategory;
    if (cats.isEmpty) {
      return _buildEmptyState(
        theme,
        'No spending data',
        'Add expenses to see a breakdown',
      );
    }

    final total = cats.values.fold(0.0, (s, v) => s + v);
    final colors = [
      accentColor,
      brandGreen,
      Colors.orange,
      Colors.purple,
      errorColor,
      Colors.teal,
    ];

    return _card(
      theme,
      'Spending Breakdown',
      Icons.donut_large,
      null,
      Column(
        children: cats.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final cat = entry.value;
          final pct = total > 0 ? cat.value / total : 0.0;
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
                        cat.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.compact(cat.value),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
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

  // ─── Daily Spending Bars ─────────────────────────────────────────────────────
  Widget _buildDailySpendingBars(ThemeData theme) {
    final daily = dailySpending;
    if (daily.isEmpty) return const SizedBox.shrink();

    final maxAmt = daily
        .map((d) => d.amount)
        .fold(0.0, (a, b) => a > b ? a : b);
    final showLabels = daily.length <= 14;

    return _card(
      theme,
      'Daily Spending',
      Icons.bar_chart,
      null,
      Column(
        children: [
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: daily.map((d) {
                final ratio = maxAmt > 0 ? d.amount / maxAmt : 0.0;
                final isMax = d.amount == maxAmt && maxAmt > 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Tooltip(
                      message:
                          '${d.day}\n${CurrencyFormatter.format(d.amount)}',
                      child: Container(
                        height: 110 * ratio + 4,
                        decoration: BoxDecoration(
                          color: isMax
                              ? errorColor
                              : accentColor.withOpacity(0.7),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (showLabels) ...[
            const SizedBox(height: 4),
            Row(
              children: daily
                  .map(
                    (d) => Expanded(
                      child: Text(
                        d.day.split('/').first,
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total: ${CurrencyFormatter.format(filteredExpenses)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Text(
                'Avg: ${CurrencyFormatter.format(avgDailySpend)}/day',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Day of Week Activity ────────────────────────────────────────────────────
  Widget _buildDayOfWeekActivity(ThemeData theme) {
    final counts = txByDayOfWeek;
    final maxCount = counts.fold(0, (a, b) => a > b ? a : b);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return _card(
      theme,
      'Activity by Day of Week',
      Icons.calendar_view_week,
      null,
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final ratio = maxCount > 0 ? counts[i] / maxCount : 0.0;
          final isMax = counts[i] == maxCount && maxCount > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  if (isMax)
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('🔥', style: TextStyle(fontSize: 8)),
                    ),
                  Text(
                    '${counts[i]}',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: 70 * ratio + 4,
                    decoration: BoxDecoration(
                      color: isMax ? accentColor : accentColor.withOpacity(0.4),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[i],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Top Expenses ─────────────────────────────────────────────────────────────
  Widget _buildTopExpenses(ThemeData theme) {
    final top = topExpenses;
    if (top.isEmpty) return const SizedBox.shrink();
    final maxAmt = _amt(top.first) + _fee(top.first);

    return _card(
      theme,
      'Top 5 Expenses',
      Icons.leaderboard,
      null,
      Column(
        children: top.asMap().entries.map((entry) {
          final idx = entry.key;
          final tx = entry.value;
          final total = _amt(tx) + _fee(tx);
          final ratio = maxAmt > 0 ? total / maxAmt : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: idx == 0
                            ? Colors.amber.shade400
                            : idx == 1
                            ? Colors.grey.shade400
                            : accentColor.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tx['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.compact(total),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: errorColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(
                      idx == 0
                          ? Colors.amber.shade400
                          : accentColor.withOpacity(0.7),
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

  // ─── Export Button (PDF only) ────────────────────────────────────────────────
  Widget _buildExportButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isGeneratingPDF ? null : generatePDF,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
            : const Icon(Icons.share, size: 20),
        label: Text(
          isGeneratingPDF ? 'Generating…' : 'Share PDF Report',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  // ─── Transaction Card ────────────────────────────────────────────────────────
  Widget buildTransactionCard(Map<String, dynamic> tx, ThemeData theme) {
    final isIncome = tx['type'] == 'income';
    final amount = _amt(tx);
    final fee = _fee(tx);
    final date = DateTime.parse(tx['date']);
    final total = isIncome ? amount : amount + fee;

    IconData icon;
    Color iconColor;
    switch (tx['type']) {
      case 'income':
        icon = Icons.arrow_circle_down_rounded;
        iconColor = brandGreen;
        break;
      case 'budget_finalized':
        icon = Icons.check_circle;
        iconColor = accentColor;
        break;
      case 'savings_deduction':
      case 'saving_deposit':
        icon = Icons.savings;
        iconColor = brandGreen;
        break;
      default:
        icon = Icons.arrow_circle_up_rounded;
        iconColor = errorColor;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['title'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      DateFormat('HH:mm').format(date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (fee > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+fee',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _getTypeLabel(tx['type']),
                  style: TextStyle(
                    fontSize: 10,
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(total)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? brandGreen : errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Reusable Card Container ─────────────────────────────────────────────────
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ─── Collapsible section ────────────────────────────────────────────────────
  Widget _collapsible(
    String title,
    bool expanded,
    VoidCallback onTap,
    Widget child,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          child: expanded ? child : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState(ThemeData theme, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 52,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Model Classes ────────────────────────────────────────────────────────────
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
