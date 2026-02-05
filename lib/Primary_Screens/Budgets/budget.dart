import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Note: Replace with your actual project imports
// import 'package:final_project/Components/Custom_header.dart';

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

  // -------------------- Persistence --------------------
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FD,
      ), // Modern light grey-blue background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: const Text(
          "My Budgets",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : budgets.isEmpty
          ? buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: budgets.length,
                    itemBuilder: (context, index) =>
                        buildBudgetCard(budgets[index]),
                  ),
                ),
                _buildAddFab(),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BudgetDetailScreen(budget: budget, onUpdate: saveBudgets),
              ),
            ).then((_) => setState(() {})),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        budget.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      _buildPopupMenu(budget),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Budget",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            formatCurrency(budget.total),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isOver ? "Overspend" : "Remaining",
                            style: TextStyle(
                              color: isOver ? Colors.red : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            formatCurrency(remaining.abs()),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: isOver ? Colors.red : Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (totalSpent / budget.total).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[200],
                      color: isOver ? Colors.red : Colors.blueAccent,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(Budget budget) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_horiz, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text("Edit Budget Amount")),
        const PopupMenuItem(
          value: 'delete',
          child: Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
      onSelected: (val) {
        if (val == 'edit') showEditBudgetDialog(budget);
        if (val == 'delete') {
          setState(() => budgets.remove(budget));
          saveBudgets();
        }
      },
    );
  }

  Widget _buildAddFab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 5,
        ),
        onPressed: showAddBudgetDialog,
        child: const Text(
          "Create New Budget",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 100,
            color: Colors.blueGrey[100],
          ),
          const SizedBox(height: 20),
          const Text(
            "No active budgets",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 40),
          _buildAddFab(),
        ],
      ),
    );
  }

  // -------------------- Dialogs --------------------
  void showAddBudgetDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "New Budget",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Budget Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Initial Amount",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                  setState(
                    () => budgets.add(
                      Budget(
                        name: nameCtrl.text,
                        total: double.parse(amountCtrl.text),
                      ),
                    ),
                  );
                  saveBudgets();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text("Create"),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void showEditBudgetDialog(Budget budget) {
    final amountCtrl = TextEditingController(text: budget.total.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Budget Amount"),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Total Budget"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() => budget.total = double.parse(amountCtrl.text));
              saveBudgets();
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
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
    bool isOver = remaining < 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(widget.budget.name),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isOver ? Colors.red[50] : Colors.blue[50],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOver ? "Deficit" : "Available",
                      style: TextStyle(
                        color: isOver ? Colors.red : Colors.blue[800],
                      ),
                    ),
                    Text(
                      "Ksh ${remaining.abs().toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isOver ? Colors.red : Colors.blue[900],
                      ),
                    ),
                  ],
                ),
                Icon(
                  isOver
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  size: 40,
                  color: isOver ? Colors.red : Colors.blue,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Expenses",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.budget.expenses.length,
              itemBuilder: (context, index) {
                final expense = widget.budget.expenses[index];
                return Card(
                  elevation: 0,
                  color: Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      expense.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text("Ksh ${expense.amount.toStringAsFixed(0)}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () =>
                              showExpenseDialog(expense: expense, index: index),
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
          _buildAddExpenseButton(),
        ],
      ),
    );
  }

  Widget _buildAddExpenseButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () => showExpenseDialog(),
        child: const Text("Add New Expense"),
      ),
    );
  }

  void showExpenseDialog({Expense? expense, int? index}) {
    final nameCtrl = TextEditingController(text: expense?.name ?? "");
    final amountCtrl = TextEditingController(
      text: expense?.amount.toString() ?? "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense == null ? "New Expense" : "Edit Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Description"),
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
                      name: nameCtrl.text,
                      amount: double.parse(amountCtrl.text),
                    ),
                  );
                } else {
                  widget.budget.expenses[index!] = Expense(
                    name: nameCtrl.text,
                    amount: double.parse(amountCtrl.text),
                  );
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
