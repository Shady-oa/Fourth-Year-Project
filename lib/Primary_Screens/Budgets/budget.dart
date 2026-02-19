import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Currency formatting utility
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');
  static String format(double amount) =>
      'Ksh ${_formatter.format(amount.round())}';
}

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
    budgets =
        budgetStrings.map((s) => Budget.fromMap(json.decode(s))).toList();
    setState(() => isLoading = false);
  }

  Future<void> saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = budgets.map((b) => json.encode(b.toMap())).toList();
    await prefs.setStringList(keyBudgets, data);
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

  void showCreateBudgetDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Budget Name (e.g., Groceries)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Budget Amount (Ksh)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text) ?? 0;

              if (name.isNotEmpty && amount > 0) {
                final newBudget = Budget(name: name, total: amount);
                budgets.add(newBudget);
                await saveBudgets();
                await sendNotification(
                  '💼 Budget Created',
                  'New budget "$name" created with ${CurrencyFormatter.format(amount)}',
                );
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Budget "$name" created successfully'),
                    backgroundColor: brandGreen,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  /// ✅ UPDATED: Uses bottom sheet for edit, blocks editing if finalized
  void showBudgetOptionsBottomSheet(Budget budget) {
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
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Budget name header
              Text(
                budget.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (budget.isChecked)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Finalized — editing disabled',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Edit option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: budget.isChecked
                        ? Colors.grey.shade100
                        : accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: budget.isChecked ? Colors.grey : accentColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Edit Budget',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: budget.isChecked ? Colors.grey : null,
                  ),
                ),
                subtitle: budget.isChecked
                    ? const Text('Unfinalize budget to edit',
                        style: TextStyle(fontSize: 11))
                    : null,
                onTap: budget.isChecked
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _showEditBudgetDialog(budget);
                      },
              ),
              // Delete option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: errorColor, size: 20),
                ),
                title: const Text(
                  'Delete Budget',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: errorColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteBudget(budget);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBudgetDialog(Budget budget) {
    final nameCtrl = TextEditingController(text: budget.name);
    final amountCtrl = TextEditingController(text: budget.total.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Budget Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Budget Amount',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (name.isNotEmpty && amount > 0) {
                budget.name = name;
                budget.total = amount;
                await saveBudgets();
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Budget updated successfully'),
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

  Future<void> _deleteBudget(Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this budget?'),
            const SizedBox(height: 12),
            Text(budget.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will NOT affect your total balance or transactions.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange.shade900),
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
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: errorColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      budgets.remove(budget);
      await saveBudgets();
      await sendNotification(
        '🗑️ Budget Deleted',
        'Budget "${budget.name}" has been deleted',
      );
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget deleted successfully'),
            backgroundColor: brandGreen,
          ),
        );
      }
    }
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
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      buildFilterChip('All', 'all', theme),
                      const SizedBox(width: 8),
                      buildFilterChip('Finalized', 'checked', theme),
                      const SizedBox(width: 8),
                      buildFilterChip('Active', 'unchecked', theme),
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
                                  color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No budgets found',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to create your first budget',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade500),
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
                              return buildBudgetCard(filteredBudgets[index]);
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

  Widget buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = filter == value;
    return GestureDetector(
      onTap: () => setState(() => filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha(80),
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

  Widget buildBudgetCard(Budget budget) {
    final theme = Theme.of(context);
    final totalSpent = budget.totalSpent;
    final amountLeft = budget.amountLeft;
    final progress = (totalSpent / budget.total).clamp(0.0, 1.0);
    final isOverBudget = totalSpent > budget.total;

    return GestureDetector(
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: budget.isChecked
                ? accentColor.withOpacity(0.5)
                : theme.colorScheme.onSurface.withAlpha(20),
            width: budget.isChecked ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.account_balance_wallet,
                            color: accentColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (budget.isChecked)
                              Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 14, color: brandGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Finalized',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: brandGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ✅ UPDATED: Three-dot opens bottom sheet
                IconButton(
                  icon: Icon(Icons.more_vert,
                      color: theme.colorScheme.onSurface),
                  onPressed: () => showBudgetOptionsBottomSheet(budget),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(120)),
                    ),
                    Text(
                      CurrencyFormatter.format(budget.total),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Left',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(120)),
                    ),
                    Text(
                      CurrencyFormatter.format(amountLeft),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? errorColor : brandGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent: ${CurrencyFormatter.format(totalSpent)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(120)),
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(120),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        theme.colorScheme.onSurface.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation(
                      isOverBudget ? errorColor : accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
  String id;
  String name;
  double amount;
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