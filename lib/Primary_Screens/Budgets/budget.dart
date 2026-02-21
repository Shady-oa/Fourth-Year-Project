// ─────────────────────────────────────────────────────────────────────────────
// Primary_Screens/Budgets/budget.dart  (UPDATED — screen only)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_card.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_confirm_sheet.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_detail.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_filter_chip.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_options_sheet.dart';
import 'package:final_project/Primary_Screens/Budgets/create_budget_sheet.dart';
import 'package:final_project/Primary_Screens/Budgets/edit_budget_sheet.dart';

import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_type.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetPage extends StatefulWidget {
  final Function(String, double, String)? onTransactionAdded;
  final Function(String, double)? onExpenseDeleted;

  const BudgetPage({super.key, this.onTransactionAdded, this.onExpenseDeleted});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  static const String keyBudgets = 'budgets';

  List<Budget> budgets = [];
  String filter = 'all';
  bool isLoading = true;
  final userUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final budgetStrings = prefs.getStringList(keyBudgets) ?? [];
    budgets = budgetStrings.map((s) => Budget.fromMap(json.decode(s))).toList();
    setState(() => isLoading = false);
  }

  Future<void> saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = budgets.map((b) => json.encode(b.toMap())).toList();
    await prefs.setStringList(keyBudgets, data);
  }

  /// Save a local notification (offline, no Firestore).
  Future<void> sendNotification(String title, String message) async {
    await LocalNotificationStore.saveNotification(
      title: title,
      message: message,
      type: NotificationType.budget,
    );
  }

  // ── Handlers passed into sheets ───────────────────────────────────────────

  void showCreateBudgetDialog() {
    showCreateBudgetSheet(
      context: context,
      onBudgetCreated: (name, amount) async {
        final newBudget = Budget(name: name, total: amount);
        budgets.add(newBudget);
        await saveBudgets();
        await sendNotification(
          'Budget Created',
          'New budget "$name" created with ${CurrencyFormatter.format(amount)}',
        );
        setState(() {});
        if (mounted) AppToast.success(context, 'Budget "$name" created successfully');
      },
    );
  }

  void showBudgetOptionsBottomSheet(Budget budget) {
    showBudgetOptionsSheet(
      context: context,
      budget: budget,
      onEdit: () => _showEditBudgetDialog(budget),
      onDelete: () => _deleteBudget(budget),
    );
  }

  void _showEditBudgetDialog(Budget budget) {
    showEditBudgetSheet(
      context: context,
      budget: budget,
      onSaved: (name, amount) async {
        budget.name = name;
        budget.total = amount;
        await saveBudgets();
        setState(() {});
        if (mounted) AppToast.success(context, 'Budget updated successfully');
      },
    );
  }

  Future<void> _deleteBudget(Budget budget) async {
    showBudgetConfirmSheet(
      context: context,
      title: 'Delete Budget',
      icon: Icons.delete_outline,
      iconColor: errorColor,
      rows: [
        BudgetConfirmRow('Budget', budget.name),
        BudgetConfirmRow('Amount', CurrencyFormatter.format(budget.total)),
        BudgetConfirmRow('Spent', CurrencyFormatter.format(budget.totalSpent)),
      ],
      note: 'This will NOT affect your total balance or transactions.',
      noteColor: Colors.orange,
      confirmLabel: 'Delete Budget',
      confirmColor: errorColor,
      onConfirm: () async {
        budgets.remove(budget);
        await saveBudgets();
        await sendNotification(
          'Budget Deleted',
          'Budget "${budget.name}" has been deleted',
        );
        setState(() {});
        if (mounted) AppToast.success(context, 'Budget deleted successfully');
      },
    );
  }

  List<Budget> get filteredBudgets {
    if (filter == 'all') return budgets;
    if (filter == 'checked') return budgets.where((b) => b.isChecked).toList();
    return budgets.where((b) => !b.isChecked).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const CustomHeader(headerName: "Budgets"),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      BudgetFilterChip(
                        label: 'All',
                        value: 'all',
                        selectedFilter: filter,
                        onSelected: (v) => setState(() => filter = v),
                      ),
                      const SizedBox(width: 8),
                      BudgetFilterChip(
                        label: 'Finalized',
                        value: 'checked',
                        selectedFilter: filter,
                        onSelected: (v) => setState(() => filter = v),
                      ),
                      const SizedBox(width: 8),
                      BudgetFilterChip(
                        label: 'Active',
                        value: 'unchecked',
                        selectedFilter: filter,
                        onSelected: (v) => setState(() => filter = v),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredBudgets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No budgets found',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to create your first budget',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadBudgets,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredBudgets.length,
                            itemBuilder: (context, index) {
                              final budget = filteredBudgets[index];
                              return BudgetCard(
                                budget: budget,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BudgetDetailPage(
                                        budgetId: budget.id,
                                        onBudgetUpdated: loadBudgets,
                                      ),
                                    ),
                                  );
                                  loadBudgets();
                                },
                                onMorePressed: () =>
                                    showBudgetOptionsBottomSheet(budget),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCreateBudgetDialog,
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
