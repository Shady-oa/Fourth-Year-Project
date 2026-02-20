import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/back_button.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Currency formatting utility
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');
  static String format(double amount) =>
      'Ksh ${_formatter.format(amount.round())}';
}

class BudgetDetailPage extends StatefulWidget {
  final String budgetId;
  final VoidCallback? onBudgetUpdated;

  const BudgetDetailPage({
    super.key,
    required this.budgetId,
    this.onBudgetUpdated,
  });

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends State<BudgetDetailPage> {
  static const String keyBudgets = 'budgets';
  static const String keyTransactions = 'transactions';

  Budget? budget;
  bool isLoading = true;
  bool _isToggling = false; // Prevent double-tap
  final userUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    loadBudget();
  }

  Future<void> loadBudget() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final budgetStrings = prefs.getStringList(keyBudgets) ?? [];
    final budgets = budgetStrings
        .map((s) => Budget.fromMap(json.decode(s)))
        .toList();
    budget = budgets.firstWhere(
      (b) => b.id == widget.budgetId,
      orElse: () => throw Exception('Budget not found'),
    );
    setState(() => isLoading = false);
  }

  Future<void> saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetStrings = prefs.getStringList(keyBudgets) ?? [];
    final budgets = budgetStrings
        .map((s) => Budget.fromMap(json.decode(s)))
        .toList();
    final index = budgets.indexWhere((b) => b.id == widget.budgetId);
    if (index != -1 && budget != null) {
      budgets[index] = budget!;
    }
    final data = budgets.map((b) => json.encode(b.toMap())).toList();
    await prefs.setStringList(keyBudgets, data);
    widget.onBudgetUpdated?.call();
  }

  Future<void> sendNotification(String title, String message) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .collection('notifications')
          .add({
            'title': title,
            'message': message,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  void showAddExpenseDialog() {
    if (budget == null || budget!.isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Budget is finalized. Toggle off to add expenses.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Expense Title (e.g., Lunch)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Amount (Ksh)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (name.isNotEmpty && amount > 0) {
                Navigator.pop(context);
                _showBudgetDetailConfirmSheet(
                  title: 'Confirm Expense',
                  icon: Icons.receipt_long,
                  iconColor: accentColor,
                  rows: [
                    _BudgetDetailRow('Budget', budget!.name),
                    _BudgetDetailRow('Expense', name),
                    _BudgetDetailRow(
                      'Amount',
                      CurrencyFormatter.format(amount),
                      highlight: true,
                    ),
                    _BudgetDetailRow(
                      'Remaining After',
                      CurrencyFormatter.format(budget!.amountLeft - amount),
                    ),
                  ],
                  confirmLabel: 'Add Expense',
                  confirmColor: accentColor,
                  onConfirm: () async {
                    final newExpense = Expense(name: name, amount: amount);
                    budget!.expenses.add(newExpense);
                    await saveBudgets();
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Expense "$name" added'),
                          backgroundColor: brandGreen,
                        ),
                      );
                    }
                  },
                );
              }
            },
            child: const Text('Continue ›'),
          ),
        ],
      ),
    );
  }

  /// ✅ UPDATED: Bottom sheet for expense edit & delete
  void showExpenseOptionsBottomSheet(Expense expense) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                expense.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                CurrencyFormatter.format(expense.amount),
                style: TextStyle(
                  color: errorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Edit Expense',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditExpenseDialog(expense);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: errorColor,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Delete Expense',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: errorColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteExpense(expense);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditExpenseDialog(Expense expense) {
    if (budget == null || budget!.isChecked) return;

    final nameCtrl = TextEditingController(text: expense.name);
    final amountCtrl = TextEditingController(text: expense.amount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Expense Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (name.isNotEmpty && amount > 0) {
                expense.name = name;
                expense.amount = amount;
                await saveBudgets();
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Expense updated'),
                    backgroundColor: brandGreen,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    if (budget == null || budget!.isChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Budget is finalized. Toggle off to delete.'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${expense.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      budget!.expenses.remove(expense);
      await saveBudgets();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense deleted'),
          backgroundColor: brandGreen,
        ),
      );
    }
  }

  Future<void> exportAsPDF() async {
    if (budget == null) return;
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd MMM yyyy');
      final now = DateTime.now();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BUDGET REPORT',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Budget Name: ${budget!.name}',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Generated: ${dateFormat.format(now)}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(5),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BUDGET SUMMARY',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Budget Amount: ${CurrencyFormatter.format(budget!.total)}',
                      ),
                      pw.Text(
                        'Amount Spent: ${CurrencyFormatter.format(budget!.totalSpent)}',
                      ),
                      pw.Text(
                        'Remaining Balance: ${CurrencyFormatter.format(budget!.amountLeft)}',
                      ),
                      pw.Text(
                        'Status: ${budget!.isChecked ? "FINALIZED" : "ACTIVE"}',
                      ),
                      if (budget!.isChecked && budget!.checkedDate != null)
                        pw.Text(
                          'Finalized on: ${dateFormat.format(budget!.checkedDate!)}',
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'EXPENSE BREAKDOWN',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                if (budget!.expenses.isEmpty)
                  pw.Text('No expenses recorded')
                else
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Expense',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Amount',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Date',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...budget!.expenses.map(
                        (exp) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(exp.name),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                CurrencyFormatter.format(exp.amount),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                dateFormat.format(exp.createdDate),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Text(
                  'Total Expenses: ${CurrencyFormatter.format(budget!.totalSpent)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/budget_${budget!.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Budget Report: ${budget!.name}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exported successfully'),
            backgroundColor: brandGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  /// ✅ UPDATED: Called from toggle switch
  Future<void> toggleCheckBudget(bool newValue) async {
    if (budget == null || _isToggling) return;
    setState(() => _isToggling = true);

    final prefs = await SharedPreferences.getInstance();

    if (newValue) {
      // Finalize budget
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finalize Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will create a collective transaction and deduct the total spent amount from your balance.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount to deduct:'),
                    Text(
                      CurrencyFormatter.format(budget!.totalSpent),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ You will not be able to add, edit, or delete expenses until toggled off.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Finalize'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final txString = prefs.getString(keyTransactions) ?? '[]';
        final transactions = List<Map<String, dynamic>>.from(
          json.decode(txString),
        );
        final collectiveTransaction = {
          'title': 'Budget: ${budget!.name} (Finalized)',
          'amount': budget!.totalSpent,
          'type': 'budget_finalized',
          'transactionCost': 0.0,
          'date': DateTime.now().toIso8601String(),
          'budgetId': budget!.id,
        };
        transactions.insert(0, collectiveTransaction);
        await prefs.setString(keyTransactions, json.encode(transactions));

        budget!.isChecked = true;
        budget!.checkedDate = DateTime.now();
        await saveBudgets();

        await sendNotification(
          '✓ Budget Finalized',
          'Budget "${budget!.name}" has been finalized. ${CurrencyFormatter.format(budget!.totalSpent)} deducted from balance.',
        );
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Budget finalized. ${CurrencyFormatter.format(budget!.totalSpent)} deducted',
              ),
              backgroundColor: brandGreen,
            ),
          );
        }
      }
    } else {
      // Un-finalize budget
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unfinalize Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will remove the collective transaction and restore the deducted amount back to your balance.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: brandGreen),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount to restore:'),
                    Text(
                      CurrencyFormatter.format(budget!.totalSpent),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Unfinalize'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final txString = prefs.getString(keyTransactions) ?? '[]';
        final transactions = List<Map<String, dynamic>>.from(
          json.decode(txString),
        );
        transactions.removeWhere(
          (tx) =>
              tx['type'] == 'budget_finalized' && tx['budgetId'] == budget!.id,
        );
        await prefs.setString(keyTransactions, json.encode(transactions));

        budget!.isChecked = false;
        budget!.checkedDate = null;
        await saveBudgets();

        await sendNotification(
          '○ Budget Unfinalized',
          'Budget "${budget!.name}" has been unfinalized. ${CurrencyFormatter.format(budget!.totalSpent)} restored to balance.',
        );
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Budget unfinalized. ${CurrencyFormatter.format(budget!.totalSpent)} restored',
              ),
              backgroundColor: brandGreen,
            ),
          );
        }
      }
    }

    setState(() => _isToggling = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading || budget == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalSpent = budget!.totalSpent;
    final amountLeft = budget!.amountLeft;
    final isOverBudget = totalSpent > budget!.total;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        leading: const CustomBackButton(),
        title: Text(
          budget!.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Export PDF Button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: exportAsPDF,
            tooltip: 'Export as PDF',
          ),
          // ✅ UPDATED: Toggle switch replacing icon button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  budget!.isChecked ? 'On' : 'Off',
                  style: TextStyle(
                    fontSize: 12,
                    color: budget!.isChecked ? brandGreen : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: budget!.isChecked,
                    onChanged: _isToggling ? null : toggleCheckBudget,
                    activeThumbColor: brandGreen,
                    activeTrackColor: brandGreen.withOpacity(0.3),
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget Amount',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(budget!.total),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (budget!.isChecked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: brandGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'FINALIZED',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spent',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(totalSpent),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Balance',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(amountLeft),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: isOverBudget
                                  ? Colors.red.shade200
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Expenses Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expenses',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${budget!.expenses.length} items',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (budget!.isChecked)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Budget is finalized. Toggle off to modify expenses.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Expenses List
          Expanded(
            child: budget!.expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No expenses yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (!budget!.isChecked)
                          Text(
                            'Tap + to add an expense',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: budget!.expenses.length,
                    itemBuilder: (context, index) {
                      return buildExpenseCard(budget!.expenses[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: budget!.isChecked
          ? null
          : FloatingActionButton(
              onPressed: showAddExpenseDialog,
              backgroundColor: accentColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  /// ✅ UPDATED: No icons, 24h time, tap opens bottom sheet
  Widget buildExpenseCard(Expense expense) {
    final theme = Theme.of(context);
    // ✅ 24-hour format
    final timeStr = DateFormat('HH:mm').format(expense.createdDate);
    final dateStr = DateFormat('dd MMM yyyy').format(expense.createdDate);

    return GestureDetector(
      onTap: budget!.isChecked
          ? null
          : () => showExpenseOptionsBottomSheet(expense),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: budget!.isChecked
                ? Colors.orange.shade200
                : theme.colorScheme.onSurface.withAlpha(15),
            width: budget!.isChecked ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ✅ No icon — clean minimal list
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr · $timeStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(expense.amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: errorColor,
                  ),
                ),
                if (!budget!.isChecked)
                  Text(
                    'tap to edit',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── BUDGET DETAIL CONFIRMATION BOTTOM SHEET ──────────────────────────────
  void _showBudgetDetailConfirmSheet({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_BudgetDetailRow> rows,
    String? note,
    Color noteColor = Colors.orange,
    required String confirmLabel,
    required Color confirmColor,
    required Future<void> Function() onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isBusy = false;
        return StatefulBuilder(
          builder: (ctx, setSheet) => Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          row.label,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          row.value,
                          style: TextStyle(
                            fontWeight: row.highlight
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: row.highlight ? 15 : 13,
                            color: row.highlight ? iconColor : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (note != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: noteColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: noteColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: noteColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Go Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isBusy
                            ? null
                            : () async {
                                setSheet(() => isBusy = true);
                                await onConfirm();
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                        child: isBusy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                confirmLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Budget Model
class Budget {
  String id;
  String name;
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
  String id;
  String name;
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

/// Data class for [_BudgetDetailPageState._showBudgetDetailConfirmSheet].
class _BudgetDetailRow {
  final String label;
  final String value;
  final bool highlight;
  const _BudgetDetailRow(this.label, this.value, {this.highlight = false});
}
