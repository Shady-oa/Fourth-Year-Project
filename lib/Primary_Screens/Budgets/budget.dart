import 'dart:convert';

import 'package:final_project/Components/Custom_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper to capitalize first letter
extension StringExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => BudgetScreenState();
}

class BudgetScreenState extends State<BudgetScreen> {
  List<Budget> budgets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetStrings = prefs.getStringList('budgets') ?? [];
    setState(() {
      budgets = budgetStrings
          .map((s) => Budget.fromMap(json.decode(s)))
          .toList();
      isLoading = false;
    });
  }

  Future<void> saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = budgets.map((b) => json.encode(b.toMap())).toList();
    await prefs.setStringList('budgets', data);
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'Ksh ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: CustomHeader(headerName: "My Budgets"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : budgets.isEmpty
          ? buildEmptyState(Theme.of(context))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: budgets.length,
                    itemBuilder: (context, index) =>
                        buildBudgetCard(budgets[index]),
                  ),
                ),
                _buildAddFab(Theme.of(context)),
              ],
            ),
    );
  }

  Widget buildBudgetCard(Budget budget) {
    double totalSpent = budget.expenses.fold(
      0,
      (sum, item) => sum + item.amount,
    );
    double remaining = budget.total - totalSpent;
    bool isOver = remaining < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BudgetDetailScreen(budget: budget, onUpdate: saveBudgets),
          ),
        ).then((_) => setState(() {})),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budget.name.toCapitalized(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildPopupMenu(budget),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatCurrency(budget.total),
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isOver
                        ? "Over by ${formatCurrency(remaining.abs())}"
                        : "Left: ${formatCurrency(remaining)}",
                    style: TextStyle(
                      color: isOver
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (totalSpent / budget.total).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[100],
                  color: isOver ? Colors.red : Colors.blueAccent,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(Budget budget) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (val) {
        if (val == 'edit') showAddBudgetDialog(budget: budget);
        if (val == 'delete') {
          setState(() => budgets.remove(budget));
          saveBudgets();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text("Edit Name/Amount")),
        const PopupMenuItem(
          value: 'delete',
          child: Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Widget _buildAddFab(dynamic theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () => showAddBudgetDialog(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Add another Budget',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void showAddBudgetDialog({Budget? budget}) {
    final nameCtrl = TextEditingController(text: budget?.name ?? "");
    final amountCtrl = TextEditingController(
      text: budget?.total.toString() ?? "",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              budget == null ? "New Budget" : "Edit Budget",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount (Ksh)"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    if (budget == null) {
                      budgets.add(
                        Budget(
                          name: nameCtrl.text.trim(),
                          total: double.tryParse(amountCtrl.text) ?? 0,
                        ),
                      );
                    } else {
                      budget.name = nameCtrl.text.trim();
                      budget.total = double.tryParse(amountCtrl.text) ?? 0;
                    }
                  });
                  saveBudgets();
                  Navigator.pop(context);
                }
              },
              child: const Text("Save Budget"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyState(dynamic theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_rounded, size: 80, color: Colors.grey[400]),
            Text('No Budgets Yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create a budget to start your journey.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),

            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => showAddBudgetDialog(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Create Budget',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- DETAIL SCREEN --------------------
class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;
  final VoidCallback onUpdate;
  const BudgetDetailScreen({
    super.key,
    required this.budget,
    required this.onUpdate,
  });

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  @override
  Widget build(BuildContext context) {
    double totalSpent = widget.budget.expenses.fold(
      0,
      (sum, item) => sum + item.amount,
    );
    double remaining = widget.budget.total - totalSpent;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: Text(
          widget.budget.name.toCapitalized(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: remaining < 0
                      ? [Colors.red.shade400, Colors.red.shade700]
                      : [Colors.green.shade400, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Remaining Balance",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "KES ${remaining.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (totalSpent / widget.budget.total).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _miniStat("Budget", widget.budget.total),
                      _miniStat("Spent", totalSpent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Expenses",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (widget.budget.expenses.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.budget.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = widget.budget.expenses[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        title: Text(
                          expense.name.toCapitalized(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Ksh ${expense.amount.toStringAsFixed(0)}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () =>
                                  showExpenseDialog(expense: expense),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(
                                  () => widget.budget.expenses.removeAt(index),
                                );
                                widget.onUpdate();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (widget.budget.expenses.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No expenses added yet",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => showExpenseDialog(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Add New Expense',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          "KES ${value.toStringAsFixed(0)}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, double val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          "Ksh ${val.abs().toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void showExpenseDialog({Expense? expense}) {
    final nameCtrl = TextEditingController(text: expense?.name ?? "");
    final amountCtrl = TextEditingController(
      text: expense?.amount.toString() ?? "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense == null ? "Add Expense" : "Edit Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: "What for?"),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (expense == null) {
                  widget.budget.expenses.add(
                    Expense(
                      name: nameCtrl.text.trim(),
                      amount: double.tryParse(amountCtrl.text) ?? 0,
                    ),
                  );
                } else {
                  expense.name = nameCtrl.text.trim();
                  expense.amount = double.tryParse(amountCtrl.text) ?? 0;
                }
              });
              widget.onUpdate();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}

// -------------------- MODELS --------------------
class Budget {
  String name;
  double total;
  List<Expense> expenses;

  Budget({required this.name, required this.total, List<Expense>? expenses})
    : expenses = expenses ?? [];

  Map<String, dynamic> toMap() => {
    'name': name,
    'total': total,
    'expenses': expenses.map((e) => e.toMap()).toList(),
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    name: map['name'],
    total: (map['total'] as num).toDouble(),
    expenses:
        (map['expenses'] as List?)?.map((e) => Expense.fromMap(e)).toList() ??
        [],
  );
}

class Expense {
  String name;
  double amount;
  Expense({required this.name, required this.amount});
  Map<String, dynamic> toMap() => {'name': name, 'amount': amount};
  factory Expense.fromMap(Map<String, dynamic> map) =>
      Expense(name: map['name'], amount: (map['amount'] as num).toDouble());
}
