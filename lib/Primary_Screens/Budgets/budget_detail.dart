import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/back_button.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
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
  static const String keyTotalIncome = 'total_income';

  Budget? budget;
  bool isLoading = true;
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

    budget = budgets.firstWhere((b) => b.id == widget.budgetId);
    setState(() => isLoading = false);
  }

  Future<void> saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetStrings = prefs.getStringList(keyBudgets) ?? [];
    final budgets = budgetStrings
        .map((s) => Budget.fromMap(json.decode(s)))
        .toList();

    // Update the budget in the list
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
    if (budget == null || budget!.checked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cannot add expenses to a checked budget',
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
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text) ?? 0;

              if (name.isNotEmpty && amount > 0) {
                final newExpense = Expense(name: name, amount: amount);
                budget!.expenses.add(newExpense);
                await saveBudgets();
                Navigator.pop(context);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expense "$name" added'),
                    backgroundColor: brandGreen,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void showEditExpenseDialog(Expense expense) {
    if (budget == null || budget!.checked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cannot edit expenses in a checked budget',
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

  Future<void> deleteExpense(Expense expense) async {
    if (budget == null || budget!.checked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cannot delete expenses from a checked budget',
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

  Future<void> downloadReceipt() async {
    if (budget == null) return;

    try {
      final dateFormat = DateFormat('dd MMM yyyy');
      final now = DateTime.now();

      final receiptContent =
          '''
══════════════════════════════════════
        BUDGET RECEIPT
══════════════════════════════════════

Budget Name: ${budget!.name}
Date: ${dateFormat.format(now)}

──────────────────────────────────────
BUDGET SUMMARY
──────────────────────────────────────

Budget Amount:     ${CurrencyFormatter.format(budget!.total)}
Amount Spent:      ${CurrencyFormatter.format(budget!.totalSpent)}
Remaining Balance: ${CurrencyFormatter.format(budget!.amountLeft)}

Status: ${budget!.checked ? '✓ CHECKED' : '○ UNCHECKED'}
${budget!.checked && budget!.checkedDate != null ? 'Checked on: ${dateFormat.format(budget!.checkedDate!)}' : ''}

──────────────────────────────────────
EXPENSE BREAKDOWN
──────────────────────────────────────

${budget!.expenses.isEmpty ? 'No expenses recorded' : budget!.expenses.map((e) => '• ${e.name}\n  ${CurrencyFormatter.format(e.amount)}\n  ${dateFormat.format(e.createdDate)}').join('\n\n')}

──────────────────────────────────────
TOTAL EXPENSES: ${CurrencyFormatter.format(budget!.totalSpent)}
──────────────────────────────────────

Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}

══════════════════════════════════════
''';

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/budget_${budget!.id}_receipt.txt');
      await file.writeAsString(receiptContent);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Budget Receipt: ${budget!.name}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt downloaded successfully'),
            backgroundColor: brandGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error downloading receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading receipt: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  Future<void> toggleCheckBudget() async {
    if (budget == null) return;

    final prefs = await SharedPreferences.getInstance();

    if (!budget!.checked) {
      // CHECK BUDGET - Deduct from balance
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Check Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will deduct the total spent amount from your balance.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor),
                ),
                child: Column(
                  children: [
                    Row(
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ You will not be able to add, edit, or delete expenses until unchecked.',
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
              child: const Text('Check Budget'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Create transaction
        final txString = prefs.getString(keyTransactions) ?? '[]';
        final transactions = List<Map<String, dynamic>>.from(
          json.decode(txString),
        );

        final newTx = {
          'title': 'Budget: ${budget!.name}',
          'amount': budget!.totalSpent,
          'type': 'budget_checked',
          'date': DateTime.now().toIso8601String(),
          'budgetId': budget!.id,
        };
        transactions.insert(0, newTx);
        await prefs.setString(keyTransactions, json.encode(transactions));

        // Update budget
        budget!.checked = true;
        budget!.checkedDate = DateTime.now();
        await saveBudgets();

        await sendNotification(
          '✓ Budget Checked',
          'Budget "${budget!.name}" has been checked. ${CurrencyFormatter.format(budget!.totalSpent)} deducted from balance.',
        );

        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Budget checked. ${CurrencyFormatter.format(budget!.totalSpent)} deducted',
              ),
              backgroundColor: brandGreen,
            ),
          );
        }
      }
    } else {
      // UNCHECK BUDGET - Restore balance
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Uncheck Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will restore the deducted amount back to your balance.',
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
              child: const Text('Uncheck'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Remove the budget_checked transaction
        final txString = prefs.getString(keyTransactions) ?? '[]';
        final transactions = List<Map<String, dynamic>>.from(
          json.decode(txString),
        );

        transactions.removeWhere(
          (tx) =>
              tx['type'] == 'budget_checked' && tx['budgetId'] == budget!.id,
        );
        await prefs.setString(keyTransactions, json.encode(transactions));

        // Update budget
        budget!.checked = false;
        budget!.checkedDate = null;
        await saveBudgets();

        await sendNotification(
          '○ Budget Unchecked',
          'Budget "${budget!.name}" has been unchecked. ${CurrencyFormatter.format(budget!.totalSpent)} restored to balance.',
        );

        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Budget unchecked. ${CurrencyFormatter.format(budget!.totalSpent)} restored',
              ),
              backgroundColor: brandGreen,
            ),
          );
        }
      }
    }
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
          // Download Receipt
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: downloadReceipt,
            tooltip: 'Download Receipt',
          ),
          // Check Budget Toggle
          IconButton(
            icon: Icon(
              budget!.checked ? Icons.check_circle : Icons.check_circle_outline,
              color: budget!.checked ? brandGreen : theme.colorScheme.onSurface,
            ),
            onPressed: toggleCheckBudget,
            tooltip: budget!.checked ? 'Uncheck Budget' : 'Check Budget',
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
                    if (budget!.checked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: brandGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'CHECKED',
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

          if (budget!.checked)
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
                      'Budget is checked. Expenses are locked.',
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
                        const SizedBox(height: 8),
                        if (!budget!.checked)
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
      floatingActionButton: budget!.checked
          ? null
          : FloatingActionButton(
              onPressed: showAddExpenseDialog,
              backgroundColor: accentColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget buildExpenseCard(Expense expense) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: budget!.checked
              ? Colors.orange.shade300
              : theme.colorScheme.onSurface.withAlpha(20),
          width: budget!.checked ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_circle_up_outlined,
              color: errorColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
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
                Text(
                  dateFormat.format(expense.createdDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
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
              if (!budget!.checked)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => showEditExpenseDialog(expense),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: errorColor,
                      ),
                      onPressed: () => deleteExpense(expense),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Budget Model
class Budget {
  String id;
  String name;
  double total;
  List<Expense> expenses;
  bool checked;
  DateTime? checkedDate;
  DateTime createdDate;

  Budget({
    String? id,
    required this.name,
    required this.total,
    List<Expense>? expenses,
    this.checked = false,
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
    'checked': checked,
    'checkedDate': checkedDate?.toIso8601String(),
    'createdDate': createdDate.toIso8601String(),
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    id: map['id'],
    name: map['name'],
    total: (map['total'] as num).toDouble(),
    expenses:
        (map['expenses'] as List?)?.map((e) => Expense.fromMap(e)).toList() ??
        [],
    checked: map['checked'] ?? false,
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
    id: map['id'],
    name: map['name'],
    amount: (map['amount'] as num).toDouble(),
    createdDate: map['createdDate'] != null
        ? DateTime.parse(map['createdDate'])
        : DateTime.now(),
  );
}
