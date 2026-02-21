// ─────────────────────────────────────────────────────────────────────────────
// Primary_Screens/Budgets/budget_detail.dart  (UPDATED — screen only)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/back_button.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Budgets/add_expense_sheet.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_confirm_sheet.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_finalized_banner.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_pdf_exporter.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_summary_card.dart';
import 'package:final_project/Primary_Screens/Budgets/edit_expense_sheet.dart';
import 'package:final_project/Primary_Screens/Budgets/expense_card.dart';
import 'package:final_project/Primary_Screens/Budgets/expense_options_sheet.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // ── Handlers passed into sheets ───────────────────────────────────────────

  void showAddExpenseDialog() {
    if (budget == null || budget!.isChecked) {
      AppToast.warning(
        context,
        'Budget is finalized. Toggle off to add expenses.',
      );
      return;
    }
    showAddExpenseSheet(
      context: context,
      onExpenseAdded: (newExpense) async {
        budget!.expenses.add(newExpense);
        await saveBudgets();
        setState(() {});
        if (mounted) AppToast.success(context, 'Expense "${newExpense.name}" added');
      },
    );
  }

  void showExpenseOptionsBottomSheet(Expense expense) {
    showExpenseOptionsSheet(
      context: context,
      expense: expense,
      onEdit: () => _showEditExpenseDialog(expense),
      onDelete: () => _deleteExpense(expense),
    );
  }

  void _showEditExpenseDialog(Expense expense) {
    if (budget == null || budget!.isChecked) return;
    showEditExpenseSheet(
      context: context,
      expense: expense,
      onSaved: (name, amount) async {
        expense.name = name;
        expense.amount = amount;
        await saveBudgets();
        setState(() {});
        if (mounted) AppToast.success(context, 'Expense updated');
      },
    );
  }

  void _deleteExpense(Expense expense) {
    if (budget == null || budget!.isChecked) {
      AppToast.warning(context, 'Budget is finalized. Toggle off to delete.');
      return;
    }
    showBudgetConfirmSheet(
      context: context,
      title: 'Delete Expense',
      icon: Icons.delete_outline,
      iconColor: errorColor,
      rows: [
        BudgetConfirmRow('Expense', expense.name),
        BudgetConfirmRow(
          'Amount',
          CurrencyFormatter.format(expense.amount),
          highlight: true,
        ),
      ],
      note: 'Deleting an expense does not affect your account balance.',
      noteColor: Colors.orange,
      confirmLabel: 'Delete Expense',
      confirmColor: errorColor,
      onConfirm: () async {
        budget!.expenses.remove(expense);
        await saveBudgets();
        setState(() {});
        if (mounted) AppToast.success(context, 'Expense deleted');
      },
    );
  }

  /// Called from toggle switch — replaces AlertDialog with bottom sheet.
  Future<void> toggleCheckBudget(bool newValue) async {
    if (budget == null || _isToggling) return;
    setState(() => _isToggling = true);

    if (newValue) {
      // ── Finalize ──────────────────────────────────────────────────────────
      showBudgetConfirmSheet(
        context: context,
        title: 'Finalize Budget',
        icon: Icons.check_circle_outline,
        iconColor: brandGreen,
        rows: [
          BudgetConfirmRow('Budget', budget!.name),
          BudgetConfirmRow(
            'Amount to Deduct',
            CurrencyFormatter.format(budget!.totalSpent),
            highlight: true,
          ),
        ],
        note:
            'This will create a collective transaction and remove the total spent from your balance. '
            'You will not be able to add, edit, or delete expenses until toggled off.',
        noteColor: Colors.orange,
        confirmLabel: 'Finalize Budget',
        confirmColor: brandGreen,
        onConfirm: () async {
          final prefs = await SharedPreferences.getInstance();
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
          if (mounted)
            AppToast.success(
              context,
              'Budget finalized. ${CurrencyFormatter.format(budget!.totalSpent)} deducted',
            );
        },
      );
    } else {
      // ── Unfinalize ────────────────────────────────────────────────────────
      showBudgetConfirmSheet(
        context: context,
        title: 'Unfinalize Budget',
        icon: Icons.undo_rounded,
        iconColor: Colors.orange,
        rows: [
          BudgetConfirmRow('Budget', budget!.name),
          BudgetConfirmRow(
            'Amount to Restore',
            CurrencyFormatter.format(budget!.totalSpent),
            highlight: true,
          ),
        ],
        note:
            'This will remove the collective transaction and restore the deducted amount back to your balance.',
        noteColor: Colors.blue,
        confirmLabel: 'Unfinalize Budget',
        confirmColor: Colors.orange,
        onConfirm: () async {
          final prefs = await SharedPreferences.getInstance();
          final txString = prefs.getString(keyTransactions) ?? '[]';
          final transactions = List<Map<String, dynamic>>.from(
            json.decode(txString),
          );
          transactions.removeWhere(
            (tx) =>
                tx['type'] == 'budget_finalized' &&
                tx['budgetId'] == budget!.id,
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
          if (mounted)
            AppToast.info(
              context,
              'Budget unfinalized. ${CurrencyFormatter.format(budget!.totalSpent)} restored',
            );
        },
      );
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
            onPressed: () => exportBudgetAsPDF(context, budget!),
            tooltip: 'Export as PDF',
          ),
          // Toggle switch replacing icon button
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
          BudgetSummaryCard(budget: budget!),

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

          if (budget!.isChecked) const BudgetFinalizedBanner(),

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
                      final expense = budget!.expenses[index];
                      return ExpenseCard(
                        expense: expense,
                        isFinalized: budget!.isChecked,
                        onTap: () => showExpenseOptionsBottomSheet(expense),
                      );
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
}
