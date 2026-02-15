import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

extension StringExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

class BudgetDetailPage extends StatefulWidget {
  final Budget budget;
  final VoidCallback onUpdate;
  final Function(String title, double amount, String type)? onTransactionAdded;
  final Function(String title, double amount)? onExpenseDeleted;

  const BudgetDetailPage({
    super.key,
    required this.budget,
    required this.onUpdate,
    this.onTransactionAdded,
    this.onExpenseDeleted,
  });

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends State<BudgetDetailPage> {
  String userUid = FirebaseAuth.instance.currentUser!.uid;

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

  @override
  Widget build(BuildContext context) {
    double totalSpent = widget.budget.expenses.fold(0, (sum, item) => sum + item.amount);
    double remaining = widget.budget.total - totalSpent;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.budget.name.toCapitalized(), style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: radiusSmall, color: remaining < 0 ? errorColor : accentColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Remaining Balance", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                  Text("Ksh ${remaining.toStringAsFixed(0)}", style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      miniStat("Budget", widget.budget.total),
                      miniStat("Spent", totalSpent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Expenses", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.budget.expenses.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: widget.budget.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = widget.budget.expenses[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.1).round())),
                        ),
                      ),
                      child: ListTile(
                        title: Text(expense.name.toCapitalized(), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                        subtitle: Text("Ksh ${expense.amount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                              onPressed: () => showExpenseDialog(expense: expense),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () {
                                setState(() => widget.budget.expenses.removeAt(index));
                                widget.onUpdate();
                                widget.onExpenseDeleted?.call("${widget.budget.name}: ${expense.name}", expense.amount);
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
                      Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text("No expenses added yet", style: TextStyle(color: Colors.grey.shade600)),
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
                  decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                  child: Text('Add New Expense', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget miniStat(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        Text("Ksh ${value.toStringAsFixed(0)}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  void showExpenseDialog({Expense? expense}) {
    final nameCtrl = TextEditingController(text: expense?.name ?? "");
    final amountCtrl = TextEditingController(text: expense?.amount.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(expense == null ? "Add Expense" : "Edit Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: "What for?")),
            TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Amount")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              final name = nameCtrl.text.trim();

              if (amount > 0 && name.isNotEmpty) {
                setState(() {
                  if (expense == null) {
                    widget.budget.expenses.add(Expense(name: name, amount: amount));
                    widget.onTransactionAdded?.call("${widget.budget.name}: $name", amount, "budget_expense");

                    final totalSpent = widget.budget.expenses.fold(0.0, (sum, e) => sum + e.amount);
                    if (totalSpent > widget.budget.total) {
                      final overspent = totalSpent - widget.budget.total;
                      sendNotification('💸 Budget Exceeded', 'Your ${widget.budget.name} budget is overspent by Ksh ${overspent.toStringAsFixed(0)}');
                    }
                  } else {
                    expense.name = name;
                    expense.amount = amount;
                  }
                });
                widget.onUpdate();
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}

class Budget {
  String name;
  double total;
  List<Expense> expenses;

  Budget({required this.name, required this.total, List<Expense>? expenses}) : expenses = expenses ?? [];

  Map<String, dynamic> toMap() => {'name': name, 'total': total, 'expenses': expenses.map((e) => e.toMap()).toList()};

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
        name: map['name'],
        total: (map['total'] as num).toDouble(),
        expenses: (map['expenses'] as List?)?.map((e) => Expense.fromMap(e)).toList() ?? [],
      );
}

class Expense {
  String name;
  double amount;
  Expense({required this.name, required this.amount});
  Map<String, dynamic> toMap() => {'name': name, 'amount': amount};
  factory Expense.fromMap(Map<String, dynamic> map) => Expense(name: map['name'], amount: (map['amount'] as num).toDouble());
}