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

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');
  static String format(double amount) =>
      'Ksh ${_formatter.format(amount.round())}';
}

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  static const String keyTransactions = 'transactions';
  static const String keyBudgets = 'budgets';
  static const String keySavings = 'savings';
  static const String keyTotalIncome = 'total_income';

  List<Map<String, dynamic>> transactions = [];
  List<Budget> budgets = [];
  List<Saving> savings = [];
  double totalIncome = 0.0;

  bool isLoading = true;
  bool isGeneratingPDF = false;

  DateTime? startDate;
  DateTime? endDate;
  String? selectedBudget;
  String? selectedSaving;
  String? selectedType;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = now;
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
    final newTransactions = List<Map<String, dynamic>>.from(
      json.decode(txString),
    );

    final budgetStrings = prefs.getStringList(keyBudgets) ?? [];
    final newBudgets = budgetStrings
        .map((s) => Budget.fromMap(json.decode(s)))
        .toList();

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
    return transactions.where((tx) {
      final txDate = DateTime.parse(tx['date']);

      // Date filter
      if (startDate != null && txDate.isBefore(startDate!)) return false;
      if (endDate != null &&
          txDate.isAfter(endDate!.add(const Duration(days: 1))))
        return false;

      // Type filter
      if (selectedType != null && selectedType != 'All') {
        if (selectedType == 'Income' && tx['type'] != 'income') return false;
        if (selectedType == 'Expense' && tx['type'] == 'income') return false;
        if (selectedType == 'Savings' &&
            tx['type'] != 'savings_deduction' &&
            tx['type'] != 'saving_deposit')
          return false;
      }

      // Budget filter
      if (selectedBudget != null && selectedBudget != 'All') {
        final title = (tx['title'] ?? '').toLowerCase();
        if (!title.contains(selectedBudget!.toLowerCase())) return false;
      }

      // Saving filter
      if (selectedSaving != null && selectedSaving != 'All') {
        final title = (tx['title'] ?? '').toLowerCase();
        if (!title.contains(selectedSaving!.toLowerCase())) return false;
      }

      return true;
    }).toList();
  }

  double get filteredIncome {
    return filteredTransactions
        .where((tx) => tx['type'] == 'income')
        .fold(
          0.0,
          (sum, tx) => sum + (double.tryParse(tx['amount'].toString()) ?? 0.0),
        );
  }

  double get filteredExpenses {
    return filteredTransactions
        .where((tx) => tx['type'] != 'income')
        .fold(
          0.0,
          (sum, tx) => sum + (double.tryParse(tx['amount'].toString()) ?? 0.0),
        );
  }

  double get filteredSavings {
    return filteredTransactions
        .where(
          (tx) =>
              tx['type'] == 'savings_deduction' ||
              tx['type'] == 'saving_deposit',
        )
        .fold(
          0.0,
          (sum, tx) => sum + (double.tryParse(tx['amount'].toString()) ?? 0.0),
        );
  }

  double get savingsCompletionRate {
    if (savings.isEmpty) return 0.0;
    final achieved = savings.where((s) => s.achieved).length;
    return (achieved / savings.length) * 100;
  }

  Map<String, List<Map<String, dynamic>>> get groupedTransactions {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var tx in filteredTransactions) {
      final date = DateTime.parse(tx['date']);
      final dateKey = DateFormat('dd MMM yyyy').format(date);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(tx);
    }

    return grouped;
  }

  // Generate and share PDF
  Future<void> generatePDF() async {
    setState(() => isGeneratingPDF = true);

    try {
      final pdf = pw.Document();

      // Build PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            _buildPDFHeader(),
            pw.SizedBox(height: 24),

            // Summary Section
            pw.Text(
              'Financial Summary',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            _buildPDFSummaryCards(),
            pw.SizedBox(height: 24),

            // Transactions Table
            pw.Text(
              'Transaction Details',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            _buildPDFTransactionTable(),

            if (filteredTransactions.length > 50)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: pw.Text(
                  'Showing first 50 transactions. Total: ${filteredTransactions.length}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),

            // Footer
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Generated by Penny Finance App',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ),
      );

      // Save and share PDF
      final pdfBytes = await pdf.save();
      final fileName =
          'penny_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';

      await _sharePDF(pdfBytes, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isGeneratingPDF = false);
      }
    }
  }

  // PDF Components
  pw.Widget _buildPDFHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Penny Finance Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Period: ${DateFormat('dd MMM yyyy').format(startDate!)} - ${DateFormat('dd MMM yyyy').format(endDate!)}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Text(
          'Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _buildPDFSummaryCards() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPDFSummaryItem(
                'Total Income',
                filteredIncome,
                PdfColors.green,
              ),
              _buildPDFSummaryItem(
                'Total Expenses',
                filteredExpenses,
                PdfColors.red,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPDFSummaryItem(
                'Total Savings',
                filteredSavings,
                PdfColors.blue,
              ),
              _buildPDFSummaryItem(
                'Net Balance',
                filteredIncome - filteredExpenses,
                filteredIncome - filteredExpenses >= 0
                    ? PdfColors.green
                    : PdfColors.red,
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Number of Transactions',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                '${filteredTransactions.length}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Savings Completion Rate',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                '${savingsCompletionRate.toStringAsFixed(1)}%',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFSummaryItem(String label, double amount, PdfColor color) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            CurrencyFormatter.format(amount),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFTransactionTable() {
    if (filteredTransactions.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Center(child: pw.Text('No transactions found')),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          // Header
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _buildPDFTableCell('Date', isHeader: true),
              _buildPDFTableCell('Description', isHeader: true),
              _buildPDFTableCell('Type', isHeader: true),
              _buildPDFTableCell('Amount', isHeader: true),
            ],
          ),
          // Transactions
          ...filteredTransactions.take(50).map((tx) {
            final date = DateTime.parse(tx['date']);
            final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
            final isIncome = tx['type'] == 'income';

            return pw.TableRow(
              children: [
                _buildPDFTableCell(DateFormat('dd/MM/yy').format(date)),
                _buildPDFTableCell(tx['title'] ?? 'Unknown'),
                _buildPDFTableCell(_getTypeLabel(tx['type'])),
                _buildPDFTableCell(
                  '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(amount)}',
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  pw.Widget _buildPDFTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // Share PDF using share dialog
  Future<void> _sharePDF(List<int> pdfBytes, String fileName) async {
    try {
      // Save to temporary directory first
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Penny Finance Report',
        text:
            'Here is my financial report from ${DateFormat('dd MMM yyyy').format(startDate!)} to ${DateFormat('dd MMM yyyy').format(endDate!)}',
      );

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
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Income';
      case 'budget_finalized':
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const CustomHeader(headerName: "Report"),
        elevation: 0,
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
            tooltip: 'Share PDF Report',
          ),
        ],
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
                    buildFilters(theme),
                    sizedBoxHeightLarge,
                    buildSummarySection(theme),
                    sizedBoxHeightLarge,
                    buildTransactionsSection(theme),
                    sizedBoxHeightLarge,
                    // Share Button
                    buildPDFActionButton(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildPDFActionButton(ThemeData theme) {
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
          elevation: 2,
        ),
        icon: isGeneratingPDF
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.share, size: 24),
        label: Text(
          isGeneratingPDF ? 'Generating PDF...' : 'Share PDF Report',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildFilters(ThemeData theme) {
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
          Text(
            'Filters',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          sizedBoxHeightMedium,

          // Date Range
          Text(
            'Date Range',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
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
                    if (date != null) {
                      setState(() => startDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    startDate == null
                        ? 'Start Date'
                        : DateFormat('dd MMM yyyy').format(startDate!),
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
                    if (date != null) {
                      setState(() => endDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    endDate == null
                        ? 'End Date'
                        : DateFormat('dd MMM yyyy').format(endDate!),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          sizedBoxHeightSmall,

          // Type Filter
          Text(
            'Transaction Type',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            items: ['All', 'Income', 'Expense', 'Savings']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => selectedType = value),
          ),
          sizedBoxHeightSmall,

          // Budget Filter
          if (budgets.isNotEmpty) ...[
            Text(
              'Budget',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedBudget,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(),
              ),
              items: ['All', ...budgets.map((b) => b.name)]
                  .map(
                    (name) => DropdownMenuItem(value: name, child: Text(name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedBudget = value),
            ),
            sizedBoxHeightSmall,
          ],

          // Savings Filter
          if (savings.isNotEmpty) ...[
            Text(
              'Savings Goal',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedSaving,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(),
              ),
              items: ['All', ...savings.map((s) => s.name)]
                  .map(
                    (name) => DropdownMenuItem(value: name, child: Text(name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedSaving = value),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildSummarySection(ThemeData theme) {
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
          Text(
            'Report Summary',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          sizedBoxHeightMedium,
          buildSummaryRow('Total Income', filteredIncome, Colors.white),
          buildSummaryRow('Total Expenses', filteredExpenses, Colors.white),
          buildSummaryRow('Total Savings', filteredSavings, Colors.white),
          const Divider(color: Colors.white54, height: 24),
          buildSummaryRow(
            'Net Balance',
            filteredIncome - filteredExpenses,
            Colors.white,
            isBold: true,
          ),
          sizedBoxHeightSmall,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transactions: ${filteredTransactions.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Savings Rate: ${savingsCompletionRate.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              color: color,
              fontSize: isBold ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTransactionsSection(ThemeData theme) {
    final grouped = groupedTransactions;

    if (grouped.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: radiusSmall,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              sizedBoxHeightSmall,
              Text(
                'No transactions found',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        sizedBoxHeightMedium,
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              ...entry.value.map((tx) => buildTransactionCard(tx, theme)),
              sizedBoxHeightSmall,
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget buildTransactionCard(Map<String, dynamic> tx, ThemeData theme) {
    final isIncome = tx['type'] == 'income';
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final date = DateTime.parse(tx['date']);

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
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('HH:mm').format(date),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
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
                '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(amount)}',
                style: TextStyle(
                  fontSize: 14,
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
}

// Model Classes
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
  }) : expenses = expenses ?? [],
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
  String name;
  double amount;
  String id;
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
