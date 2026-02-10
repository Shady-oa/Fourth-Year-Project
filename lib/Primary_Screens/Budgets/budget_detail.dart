import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Budgets/budget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final String year = DateTime.now().year.toString();
  String month = DateFormat('MM').format(DateTime.now());
  String userUid = FirebaseAuth.instance.currentUser!.uid;

  void addExpense(String description, String amount) async {
    try {
      await FirebaseFirestore.instance
          .collection('statistics')
          .doc(userUid)
          .collection(year)
          .doc(month)
          .collection('transactions')
          .add({
            'type': 'expense',
            'name': widget.budget.name,
            'description': description,
            'amount': amount,
            'createdAt': FieldValue.serverTimestamp(),
          });
      showCustomToast(
        context: context,
        message: 'Expense Added Successfully!',
        backgroundColor: Colors.green,
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      showCustomToast(
        context: context,
        message: 'An error occured try again!',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalSpent = widget.budget.expenses.fold(
      0,
      (sum, item) => sum + item.amount,
    );
    double remaining = widget.budget.total - totalSpent;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.budget.name.toCapitalized(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),

                color: remaining < 0 ? errorColor : accentColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Remaining Balance",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  Text(
                    "KES ${remaining.toStringAsFixed(0)}",
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Expenses",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
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
                          horizontal: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface
                                .withAlpha((255 * 0.1).round()),
                          ),
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          expense.name.toCapitalized(),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),

        Text(
          "KES ${value.toStringAsFixed(0)}",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
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
              if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
                /*widget.budget.expenses.add(
                    Expense(
                      name: nameCtrl.text.trim(),
                      amount: double.tryParse(amountCtrl.text) ?? 0,
                    ),
                  );*/
              } else {
                /*setState(() {
                  expense!.name = nameCtrl.text.trim();
                  expense.amount = double.tryParse(amountCtrl.text) ?? 0;
                });*/
                addExpense(nameCtrl.text.trim(), amountCtrl.text.trim());
                //widget.onUpdate();
                Navigator.pop(context);
              }
              /*setState(() {
                if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) {
                  /*widget.budget.expenses.add(
                    Expense(
                      name: nameCtrl.text.trim(),
                      amount: double.tryParse(amountCtrl.text) ?? 0,
                    ),
                  );*/
                } else {
                  expense!.name = nameCtrl.text.trim();
                  expense.amount = double.tryParse(amountCtrl.text) ?? 0;
                  addExpense(
                    nameCtrl.text.trim(),
                    double.tryParse(amountCtrl.text) ?? 0,
                  );
                }
              });*/
              //widget.onUpdate();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
