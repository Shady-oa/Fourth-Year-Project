// ─────────────────────────────────────────────────────────────────────────────
// Primary_Screens/Budgets/budget_detail.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
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
import 'package:final_project/Primary_Screens/Budgets/budget_sync_service.dart';
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
  static const String _keyBudgets = 'budgets';
  static const String _keyTransactions = 'transactions';

  Budget? budget;
  bool isLoading = true;
  bool _isToggling = false;
  final userUid = FirebaseAuth.instance.currentUser!.uid;

  late final BudgetSyncService _sync;

  @override
  void initState() {
    super.initState();
    _sync = BudgetSyncService(uid: userUid);
    loadBudget();
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  // Always reads from SharedPreferences — works offline.
  // SharedPreferences is kept up-to-date by _saveBudget() on every mutation
  // and by pullAndMerge() on every BudgetPage open.

  Future<void> loadBudget() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final strings = prefs.getStringList(_keyBudgets) ?? [];
    final all = strings.map((s) => Budget.fromMap(json.decode(s))).toList();
    budget = all.firstWhere(
      (b) => b.id == widget.budgetId,
      orElse: () => throw Exception('Budget not found'),
    );
    setState(() => isLoading = false);
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  // Step 1 — mark budget dirty and write to SharedPreferences (always, offline-safe).
  // Step 2 — attempt immediate Firestore push via syncDirtyBudgets().
  //          If offline, the call throws internally and is caught silently.
  //          isDirty = true persists on disk so the next syncDirtyBudgets()
  //          call (on next app open or next loadBudgets()) retries automatically.

  Future<void> _saveBudget() async {
    if (budget == null) return;

    // Mark dirty before writing so the flag is on disk even if the app
    // is killed between the SharedPreferences write and the Firestore push.
    budget!.isDirty = true;

    final prefs = await SharedPreferences.getInstance();
    final strings = prefs.getStringList(_keyBudgets) ?? [];
    final all = strings.map((s) => Budget.fromMap(json.decode(s))).toList();

    final index = all.indexWhere((b) => b.id == widget.budgetId);
    if (index != -1) {
      all[index] = budget!;
    } else {
      all.add(budget!);
    }

    // ── Step 1: persist to SharedPreferences — instant, always works offline.
    await prefs.setStringList(
      _keyBudgets,
      all.map((b) => json.encode(b.toMap())).toList(),
    );

    widget.onBudgetUpdated?.call();

    // ── Step 2: sync to Firestore in the background — do NOT await.
    // The UI returns immediately so the user never waits on network.
    // If offline, syncDirtyBudgets catches the error silently and leaves
    // isDirty=true on disk so the next call (on app open) retries.
    unawaited(_sync.syncDirtyBudgets());
  }

  Future<void> _sendNotification(String title, String message) async {
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

  // ── Add expense ───────────────────────────────────────────────────────────

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
        // 1. Add to local model.
        budget!.expenses.add(newExpense);

        // 2. Save to SharedPreferences + push to Firestore.
        //    _saveBudget marks isDirty=true and calls syncDirtyBudgets,
        //    which calls _pushAllExpenses — the new expense is included.
        //    If offline, isDirty stays true and syncs on next app open.
        await _saveBudget();

        setState(() {});
        if (mounted) {
          AppToast.success(context, 'Expense "${newExpense.name}" added');
        }
      },
    );
  }

  // ── Edit expense ──────────────────────────────────────────────────────────

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
        // 1. Mutate in place — same object reference, same ID in Firestore.
        expense.name = name;
        expense.amount = amount;

        // 2. Save locally + push to Firestore.
        //    syncDirtyBudgets → _pushAllExpenses upserts the updated expense.
        await _saveBudget();

        setState(() {});
        if (mounted) AppToast.success(context, 'Expense updated');
      },
    );
  }

  // ── Delete expense ────────────────────────────────────────────────────────

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
        // 1. Record the deletion in the persistent pending-deletions map
        //    BEFORE removing from local list.  This survives a cold restart
        //    so that even if the app is killed offline the deletion is
        //    replayed when back online.
        await _sync.recordExpenseDeletion(budget!.id, expense.id);

        // 2. Remove from local model.
        budget!.expenses.remove(expense);

        // 3. Save locally + attempt Firestore sync.
        //    syncDirtyBudgets → _replayExpenseDeletions will delete the
        //    expense doc from Firestore. If offline the pending-deletions
        //    record stays and replays on the next sync.
        await _saveBudget();

        setState(() {});
        if (mounted) AppToast.success(context, 'Expense deleted');
      },
    );
  }

  // ── Finalize / unfinalize ─────────────────────────────────────────────────
  // Finalizing:
  //   1. Saves isChecked=true + checkedDate locally (SharedPreferences).
  //   2. Syncs the budget doc to Firestore via syncDirtyBudgets.
  //   3. Creates a transaction doc in Firestore:
  //        /statistics/{uid}/{year}/{month}/transactions/{auto-id}
  //        { type, name, amount, refId: budget.id, isLocked, createdAt }
  //   Also writes the transaction locally to SharedPreferences for offline use.
  //
  // Unfinalizing:
  //   1. Saves isChecked=false + checkedDate=null locally.
  //   2. Syncs the budget doc to Firestore.
  //   3. Deletes the Firestore transaction where refId == budget.id && type == "budget".
  //   Also removes the local SharedPreferences transaction entry.

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
            'This will create a transaction and lock expenses. '
            'Toggle off to make changes.',
        noteColor: Colors.orange,
        confirmLabel: 'Finalize Budget',
        confirmColor: brandGreen,
        onConfirm: () async {
          final now = DateTime.now();

          // 1. Write transaction to local SharedPreferences.
          final prefs = await SharedPreferences.getInstance();
          final txString = prefs.getString(_keyTransactions) ?? '[]';
          final transactions = List<Map<String, dynamic>>.from(
            json.decode(txString),
          );
          transactions.insert(0, {
            'type': 'budget',
            'name': '${budget!.name} (Finalized)',
            'amount': budget!.totalSpent,
            'refId': budget!.id,
            'isLocked': true,
            'createdAt': now.toIso8601String(),
          });
          await prefs.setString(_keyTransactions, json.encode(transactions));

          // 2. Update budget state and sync to Firestore.
          budget!.isChecked = true;
          budget!.checkedDate = now;
          await _saveBudget();

          // 3. Create the transaction document in Firestore in the background.
          //    The local SharedPreferences entry keeps the app consistent.
          //    If offline this fails silently and can be retried manually.
          unawaited(_sync.createFinalizeTransaction(budget!));

          await _sendNotification(
            '✓ Budget Finalized',
            'Budget "${budget!.name}" finalized — '
                '${CurrencyFormatter.format(budget!.totalSpent)} recorded.',
          );

          setState(() {});
          if (mounted) {
            AppToast.success(
              context,
              'Budget finalized. '
              '${CurrencyFormatter.format(budget!.totalSpent)} recorded',
            );
          }
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
            'Amount to Remove',
            CurrencyFormatter.format(budget!.totalSpent),
            highlight: true,
          ),
        ],
        note: 'This will delete the finalize transaction and unlock expenses.',
        noteColor: Colors.blue,
        confirmLabel: 'Unfinalize Budget',
        confirmColor: Colors.orange,
        onConfirm: () async {
          // 1. Remove transaction from local SharedPreferences.
          final prefs = await SharedPreferences.getInstance();
          final txString = prefs.getString(_keyTransactions) ?? '[]';
          final transactions = List<Map<String, dynamic>>.from(
            json.decode(txString),
          );
          transactions.removeWhere(
            (tx) => tx['type'] == 'budget' && tx['refId'] == budget!.id,
          );
          await prefs.setString(_keyTransactions, json.encode(transactions));

          // 2. Update budget state and sync to Firestore.
          budget!.isChecked = false;
          budget!.checkedDate = null;
          await _saveBudget();

          // 3. Delete the transaction document from Firestore in the background.
          unawaited(_sync.deleteFinalizeTransaction(budget!.id));

          await _sendNotification(
            '○ Budget Unfinalized',
            'Budget "${budget!.name}" unfinalized — transaction removed.',
          );

          setState(() {});
          if (mounted) {
            AppToast.info(context, 'Budget unfinalized. Transaction removed.');
          }
        },
      );
    }

    setState(() => _isToggling = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => exportBudgetAsPDF(context, budget!),
            tooltip: 'Export as PDF',
          ),
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
          BudgetSummaryCard(budget: budget!),
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
