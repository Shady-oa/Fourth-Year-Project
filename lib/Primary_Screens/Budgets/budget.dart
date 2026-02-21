// ─────────────────────────────────────────────────────────────────────────────
// Primary_Screens/Budgets/budget.dart  (UPDATED — search + newest-first)
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

  // ── Search ────────────────────────────────────────────────────────────────
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    loadBudgets();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
    _searchFocus.addListener(() {
      setState(() => _isSearchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
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
        // Insert at the front so new budgets appear first
        budgets.insert(0, newBudget);
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

  // ── Filtered + searched list ──────────────────────────────────────────────

  List<Budget> get filteredBudgets {
    List<Budget> result;
    if (filter == 'all') {
      result = budgets;
    } else if (filter == 'checked') {
      result = budgets.where((b) => b.isChecked).toList();
    } else {
      result = budgets.where((b) => !b.isChecked).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((b) => b.name.toLowerCase().contains(_searchQuery))
          .toList();
    }

    return result;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
                // ── Search Bar ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search budgets…',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: _isSearchFocused ? brandGreen : Colors.grey,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                _searchFocus.unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface.withAlpha(40),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: brandGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Filter Chips ─────────────────────────────────────────
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

                // ── Budget List ──────────────────────────────────────────
                Expanded(
                  child: filteredBudgets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.account_balance_wallet_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No budgets match "$_searchQuery"'
                                    : 'No budgets found',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Try a different search term'
                                    : 'Tap + to create your first budget',
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