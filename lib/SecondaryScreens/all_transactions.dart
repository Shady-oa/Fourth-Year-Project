import 'dart:convert';

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Savings/financial_service.dart';
import 'package:final_project/SecondaryScreens/Transactions/edit_transaction.dart';
import 'package:final_project/SecondaryScreens/Transactions/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Currency formatting utility
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');
  static String format(double amount) =>
      'Ksh ${_formatter.format(amount.round())}';
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const String keyTransactions = 'transactions';
  static const String keyBudgets = 'budgets';
  static const String keyTotalIncome = 'total_income';
  static const String keySavings = 'savings';

  List<Map<String, dynamic>> transactions = [];
  List<Budget> budgets = [];
  List<Saving> savings = [];
  String filter = 'all';
  bool isLoading = true;
  double totalIncome = 0.0;
  // Cached financial summary from FinancialService — always in sync with prefs.
  FinancialSummary? _summary;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    loadTransactions();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadTransactions() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final txString = prefs.getString(keyTransactions) ?? '[]';
    transactions = List<Map<String, dynamic>>.from(json.decode(txString));
    totalIncome = prefs.getDouble(keyTotalIncome) ?? 0.0;

    final budgetStrings = prefs.getStringList(keyBudgets) ?? [];
    budgets = budgetStrings.map((s) => Budget.fromMap(json.decode(s))).toList();

    final savingsStrings = prefs.getStringList(keySavings) ?? [];
    savings = savingsStrings
        .map((s) => Saving.fromMap(json.decode(s)))
        .toList();

    // Use centralised FinancialService so totals match Home / Analytics / Reports
    _summary = FinancialService.recalculateFromPrefs(prefs);

    setState(() => isLoading = false);
  }

  /// Returns true for any transaction that must be read-only.
  /// Rules:
  ///  • Any saving/budget type is always locked.
  ///  • 'expense' entries whose title starts with
  ///    'Saving fees (non-refundable)' are saving-fee re-logs created by
  ///    FinancialService.refundSavingsPrincipal — they must remain immutable
  ///    even after the linked goal is deleted.
  bool isSavingsOrBudgetTransaction(Map<String, dynamic> tx) {
    const lockedTypes = {
      'savings_deduction',
      'saving_deposit',
      'savings_withdrawal',
      'budget_finalized',
      'budget_expense',
    };
    if (lockedTypes.contains(tx['type'] ?? '')) return true;
    // Also lock saving-fee re-log entries (type == 'expense' but immutable).
    final title = (tx['title'] ?? '').toString();
    if (title.startsWith('Saving fees (non-refundable)')) return true;
    return false;
  }

  // ── Filtering ─────────────────────────────────────────────────────────────
  //
  //  'all'     → every transaction
  //  'income'  → only type == 'income'
  //  'expense' → everything that is NOT income:
  //              normal expenses, savings deposits, saving-fee re-logs,
  //              budget entries, withdrawal display rows — all fall here
  //              because they all reduce the available balance.
  List<Map<String, dynamic>> get typeFilteredTransactions {
    if (filter == 'all') return transactions;
    if (filter == 'income') {
      return transactions.where((tx) => tx['type'] == 'income').toList();
    }
    // 'expense' filter: all non-income transactions
    return transactions.where((tx) => tx['type'] != 'income').toList();
  }

  List<Map<String, dynamic>> get filteredTransactions {
    final base = typeFilteredTransactions;
    if (_searchQuery.isEmpty) return base;

    return base.where((tx) {
      final title = (tx['title'] ?? '').toString().toLowerCase();
      final type = getTypeLabel(tx['type'] ?? '').toLowerCase();
      final rawType = (tx['type'] ?? '').toString().toLowerCase();
      final reason = (tx['reason'] ?? '').toString().toLowerCase();

      String budgetName = '';
      if (tx['budgetId'] != null) {
        final b = budgets.where((b) => b.id == tx['budgetId']).toList();
        if (b.isNotEmpty) budgetName = b.first.name.toLowerCase();
      }

      return title.contains(_searchQuery) ||
          type.contains(_searchQuery) ||
          rawType.contains(_searchQuery) ||
          reason.contains(_searchQuery) ||
          budgetName.contains(_searchQuery);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get groupedTransactions {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var tx in filteredTransactions) {
      final date = DateTime.parse(tx['date']);
      final dateKey = DateFormat('dd MMM yyyy').format(date);
      if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
      grouped[dateKey]!.add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupedTx = groupedTransactions;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: _isSearchVisible
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
                style: theme.textTheme.bodyLarge,
              )
            : const Text('All Transactions'),
        centerTitle: !_isSearchVisible,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.close : Icons.search,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      buildFilterChip('All', 'all', theme),
                      const SizedBox(width: 8),
                      buildFilterChip('Income', 'income', theme),
                      const SizedBox(width: 8),
                      buildFilterChip('Expenses', 'expense', theme),
                    ],
                  ),
                ),

                buildSummaryCard(theme),

                // Info bar
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, color: accentColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap any transaction to view details. Income & expense transactions can be edited.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: filteredTransactions.isEmpty
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
                                _searchQuery.isNotEmpty
                                    ? 'No results for "$_searchQuery"'
                                    : 'No transactions found',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Text('Clear search'),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadTransactions,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: groupedTx.length,
                            itemBuilder: (context, index) {
                              final dateKey = groupedTx.keys.elementAt(index);
                              final txList = groupedTx[dateKey]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    child: Text(
                                      getDateLabel(dateKey),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha(80),
                                          ),
                                    ),
                                  ),
                                  ...txList.map((tx) {
                                    final originalIndex = transactions.indexOf(
                                      tx,
                                    );
                                    // Lock ALL savings and budget transactions.
                                    final isLocked =
                                        isSavingsOrBudgetTransaction(tx);

                                    return TransactionCard(
                                      transaction: tx,
                                      index: originalIndex,
                                      isLocked: isLocked,
                                      // Every card is tappable.
                                      // Editable types (income/expense) open
                                      // the edit form; all others show
                                      // a read-only detail view.
                                      onTap: () => EditTransactionSheet.show(
                                        context,
                                        transaction: tx,
                                        index: originalIndex,
                                        onSaved: loadTransactions,
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = filter == value;
    return GestureDetector(
      onTap: () => setState(() => filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withAlpha(80),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────
  //
  // Matches the Home page balance-card style (gradient, same typography).
  // Intentionally shows ONLY Income and Expenses to keep the Transactions
  // page focused. Balance and Saved are omitted here as they are shown on
  // the Home page.
  Widget buildSummaryCard(ThemeData theme) {
    final s = _summary;
    final income = s?.totalIncome ?? 0.0;
    final expenses = s?.totalExpenses ?? 0.0;
    final isOverspent = expenses > income;

    // Use errorColor gradient when overspent — mirrors Home page behaviour.
    final gradientStart = isOverspent ? errorColor : accentColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [gradientStart, gradientStart.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles — same as Home page balance card
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -16,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // ── Income stat ────────────────────────────────────────
                Expanded(
                  child: _buildStat(
                    label: 'Total Income',
                    amount: income,
                    icon: Icons.arrow_circle_down_rounded,
                    alignLeft: true,
                  ),
                ),

                // Divider
                Container(
                  height: 44,
                  width: 1,
                  color: Colors.white.withOpacity(0.25),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),

                // ── Expenses stat ──────────────────────────────────────
                Expanded(
                  child: _buildStat(
                    label: 'Total Expenses',
                    amount: expenses,
                    icon: Icons.arrow_circle_up_rounded,
                    alignLeft: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required double amount,
    required IconData icon,
    required bool alignLeft,
  }) {
    return Column(
      crossAxisAlignment: alignLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: alignLeft
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            if (alignLeft) ...[
              Icon(icon, color: Colors.white70, size: 13),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!alignLeft) ...[
              const SizedBox(width: 5),
              Icon(icon, color: Colors.white70, size: 13),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  String getDateLabel(String dateKey) {
    final date = DateFormat('dd MMM yyyy').parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);
    if (txDate == today) return 'Today';
    if (txDate == yesterday) return 'Yesterday';
    return dateKey;
  }

  String getTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Income';
      case 'budget_expense':
        return 'Budget';
      case 'budget_finalized':
        return 'Budget';
      case 'savings_deduction':
        return 'Savings ↓';
      case 'savings_withdrawal':
        return 'Savings ↑';
      case 'expense':
        return 'Expense';
      default:
        return 'Other';
    }
  }
}

// ─── Models (kept local for page self-sufficiency) ─────────────────────────────
class Budget {
  String name, id;
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
  String name, id;
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
  DateTime deadline;
  bool achieved;
  String walletType;
  String? walletName;
  DateTime lastUpdated;

  Saving({
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.deadline,
    this.achieved = false,
    required this.walletType,
    this.walletName,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'name': name,
    'savedAmount': savedAmount,
    'targetAmount': targetAmount,
    'deadline': deadline.toIso8601String(),
    'achieved': achieved,
    'walletType': walletType,
    'walletName': walletName,
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
    walletType: map['walletType'] ?? 'M-Pesa',
    walletName: map['walletName'],
    lastUpdated: map['lastUpdated'] != null
        ? DateTime.parse(map['lastUpdated'])
        : DateTime.now(),
  );
}
