import 'dart:convert';

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
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

  // ✅ NEW: Search state
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
    budgets =
        budgetStrings.map((s) => Budget.fromMap(json.decode(s))).toList();

    final savingsStrings = prefs.getStringList(keySavings) ?? [];
    savings =
        savingsStrings.map((s) => Saving.fromMap(json.decode(s))).toList();

    setState(() => isLoading = false);
  }

  bool isTransactionLinkedToAchievedGoal(Map<String, dynamic> tx) {
    if (tx['type'] != 'savings_deduction' &&
        tx['type'] != 'savings_withdrawal') {
      return false;
    }
    final title = tx['title'] ?? '';
    for (var saving in savings) {
      if (title.contains(saving.name) && saving.achieved) return true;
    }
    return false;
  }

  bool isTransactionLinkedToCheckedBudget(Map<String, dynamic> tx) {
    if (tx['type'] != 'budget_finalized') return false;
    final budgetId = tx['budgetId'];
    if (budgetId == null) return false;
    for (var budget in budgets) {
      if (budget.id == budgetId && budget.isChecked) return true;
    }
    return false;
  }

  Future<void> recalculateSavingsGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final txString = prefs.getString(keyTransactions) ?? '[]';
    final currentTransactions =
        List<Map<String, dynamic>>.from(json.decode(txString));

    bool savingsChanged = false;
    for (var saving in savings) {
      double calculatedAmount = 0.0;
      for (var tx in currentTransactions) {
        if ((tx['type'] == 'savings_deduction' ||
                tx['type'] == 'saving_deposit') &&
            tx['title'] != null &&
            tx['title'].toString().contains('Saved for ${saving.name}')) {
          calculatedAmount += double.tryParse(tx['amount'].toString()) ?? 0.0;
        }
      }
      if (saving.savedAmount != calculatedAmount) {
        saving.savedAmount = calculatedAmount;
        savingsChanged = true;
      }
      bool shouldBeAchieved = saving.savedAmount >= saving.targetAmount;
      if (saving.achieved != shouldBeAchieved) {
        saving.achieved = shouldBeAchieved;
        savingsChanged = true;
      }
    }
    if (savingsChanged) {
      final data = savings.map((s) => json.encode(s.toMap())).toList();
      await prefs.setStringList(keySavings, data);
    }
  }

  Future<void> deleteTransaction(int originalIndex) async {
    final tx = transactions[originalIndex];
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final transactionCost =
        double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
    final type = tx['type'];

    if (isTransactionLinkedToAchievedGoal(tx)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.lock, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Transactions linked to an achieved saving goal cannot be deleted.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ]),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
                label: 'OK', textColor: Colors.white, onPressed: () {}),
          ),
        );
      }
      return;
    }

    if (isTransactionLinkedToCheckedBudget(tx)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.lock, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Transactions from finalized budgets cannot be deleted.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ]),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
                label: 'OK', textColor: Colors.white, onPressed: () {}),
          ),
        );
      }
      return;
    }

    final totalAmount = amount + transactionCost;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this transaction?'),
            const SizedBox(height: 12),
            Text('${tx['title']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Amount: ${CurrencyFormatter.format(amount)}'),
            if (transactionCost > 0)
              Text('+ Fee: ${CurrencyFormatter.format(transactionCost)}'),
            if (transactionCost > 0)
              Text('Total: ${CurrencyFormatter.format(totalAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will affect your balance and statistics.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.orange.shade900),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      transactions.removeAt(originalIndex);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyTransactions, json.encode(transactions));

      if (type == 'income') {
        totalIncome -= amount;
        await prefs.setDouble(keyTotalIncome, totalIncome);
      }

      await recalculateSavingsGoals();
      await loadTransactions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Transaction deleted and synced with Home page'),
            backgroundColor: brandGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ✅ Applies type filter
  List<Map<String, dynamic>> get typeFilteredTransactions {
    if (filter == 'all') return transactions;
    if (filter == 'income') {
      return transactions.where((tx) => tx['type'] == 'income').toList();
    }
    return transactions.where((tx) => tx['type'] != 'income').toList();
  }

  // ✅ NEW: Search filter — case-insensitive, searches title, type, category, budget name
  List<Map<String, dynamic>> get filteredTransactions {
    final base = typeFilteredTransactions;
    if (_searchQuery.isEmpty) return base;

    return base.where((tx) {
      final title = (tx['title'] ?? '').toString().toLowerCase();
      final type = getTypeLabel(tx['type'] ?? '').toLowerCase();
      final rawType = (tx['type'] ?? '').toString().toLowerCase();

      // Also search budget name if applicable
      String budgetName = '';
      if (tx['budgetId'] != null) {
        final b = budgets.where((b) => b.id == tx['budgetId']).toList();
        if (b.isNotEmpty) budgetName = b.first.name.toLowerCase();
      }

      return title.contains(_searchQuery) ||
          type.contains(_searchQuery) ||
          rawType.contains(_searchQuery) ||
          budgetName.contains(_searchQuery);
    }).toList();
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
            : const Text("All Transactions"),
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
                      horizontal: 16.0, vertical: 8.0),
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
                // Hint bar
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swipe, color: accentColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Swipe to delete. 🔒 Achieved goals & finalized budgets are protected.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade700),
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
                              Icon(Icons.receipt_long_outlined,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No results for "$_searchQuery"'
                                    : 'No transactions found',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey.shade600),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: groupedTx.length,
                            itemBuilder: (context, index) {
                              final dateKey =
                                  groupedTx.keys.elementAt(index);
                              final txList = groupedTx[dateKey]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12.0),
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
                                    final originalIndex =
                                        transactions.indexOf(tx);
                                    return buildTransactionCard(
                                        tx, originalIndex, theme);
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
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  Widget buildSummaryCard(ThemeData theme) {
    double totalIncomeFiltered = 0;
    double totalExpenseFiltered = 0;

    for (var tx in filteredTransactions) {
      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
      final fee =
          double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
      if (tx['type'] == 'income') {
        totalIncomeFiltered += amount;
      } else {
        totalExpenseFiltered += amount + fee;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radiusSmall,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildSummaryStat(
            'Income',
            totalIncomeFiltered,
            Icons.arrow_circle_down_rounded,
            theme.colorScheme.onSurface,
          ),
          Container(
              height: 40,
              width: 1,
              color: Colors.white.withOpacity(0.3)),
          buildSummaryStat(
            'Expenses',
            totalExpenseFiltered,
            Icons.arrow_circle_up_rounded,
            theme.colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget buildSummaryStat(
      String label, double amount, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
      ],
    );
  }

  Widget buildTransactionCard(
      Map<String, dynamic> tx, int originalIndex, ThemeData theme) {
    final isIncome = tx['type'] == 'income';
    final date = DateTime.parse(tx['date']);
    // ✅ 24-hour format
    final time = DateFormat('HH:mm').format(date);
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final transactionCost =
        double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
    final totalDeducted = amount + transactionCost;
    final isLocked = isTransactionLinkedToAchievedGoal(tx) ||
        isTransactionLinkedToCheckedBudget(tx);

    IconData txIcon;
    Color iconBgColor;

    switch (tx['type']) {
      case 'income':
        txIcon = Icons.arrow_circle_down_rounded;
        iconBgColor = accentColor;
        break;
      case 'budget_expense':
        txIcon = Icons.receipt_rounded;
        iconBgColor = Colors.orange;
        break;
      case 'budget_finalized':
        txIcon = Icons.check_circle;
        iconBgColor = brandGreen;
        break;
      case 'savings_deduction':
      case 'saving_deposit':
        txIcon = Icons.savings;
        iconBgColor = brandGreen;
        break;
      case 'savings_withdrawal':
        txIcon = Icons.savings;
        iconBgColor = Colors.orange;
        break;
      default:
        txIcon = Icons.arrow_circle_up_outlined;
        iconBgColor = errorColor;
    }

    return Dismissible(
      key: Key('${tx['date']}_$originalIndex'),
      direction:
          isLocked ? DismissDirection.none : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (isLocked) return false;
        await deleteTransaction(originalIndex);
        return false;
      },
      background: isLocked
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: errorColor,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.delete_outline,
                  color: Colors.white, size: 32),
            ),
      secondaryBackground: isLocked
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: errorColor,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_outline,
                  color: Colors.white, size: 32),
            ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocked ? Colors.orange.shade300 : Colors.grey.shade200,
            width: isLocked ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(txIcon, color: iconBgColor, size: 30),
              ),
              if (isLocked)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.lock,
                        color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          title: Text(
            tx['title'] ?? "Unknown",
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Icon(Icons.access_time,
                  size: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(80)),
              const SizedBox(width: 4),
              Text(
                time,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(80)),
              ),
              if (transactionCost > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+fee',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  getTypeLabel(tx['type']),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: iconBgColor),
                ),
              ),
              Text(
                "${isIncome ? '+' : '-'} ${CurrencyFormatter.format(isIncome ? amount : totalDeducted)}",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? brandGreen : errorColor,
                ),
              ),
            ],
          ),
        ),
      ),
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

// Models
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
  })  : expenses = expenses ?? [],
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
        expenses: (map['expenses'] as List?)
                ?.map((e) => Expense.fromMap(e))
                .toList() ??
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
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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

  double get balance => targetAmount - savedAmount;

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