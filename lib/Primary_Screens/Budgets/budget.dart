import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Components/end_month.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String userUid = FirebaseAuth.instance.currentUser!.uid;
  final String year = DateTime.now().year.toString();
  String month = DateFormat('MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  void addBudget(String bName, String bAmount) async {
    try {
      await FirebaseFirestore.instance
          .collection('statistics')
          .doc(userUid)
          .collection(year)
          .doc(month)
          .collection('budgets')
          .doc(bName)
          .set({
            'bName': bName,
            'createdAt': FieldValue.serverTimestamp(),
            'dueDate': DateTime.now().lastDayOfMonth(),
            'bAmount': bAmount,
            'usedAmount': '0',
          });
      showCustomToast(
        context: context,
        message: 'Budget Added Successfully!',
        backgroundColor: Colors.green,
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      showCustomToast(
        context: context,
        message: 'An error occured try again',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
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
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withAlpha((255 * 0.5).round()),
          ),
        ),
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
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budget.name.toCapitalized(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  _buildPopupMenu(budget),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatCurrency(budget.total),
                    style: const TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    isOver
                        ? "Overspent by ${formatCurrency(remaining.abs())}"
                        : "Left: ${formatCurrency(remaining)}",
                    style: TextStyle(
                      color: isOver ? errorColor : brandGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (totalSpent / budget.total).clamp(0.0, 1.0),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha((255 * 0.1).round()),
                  color: isOver ? errorColor : accentColor,
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
          child: Text("Delete", style: TextStyle(color: errorColor)),
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
              textCapitalization: TextCapitalization.words,
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
                  addBudget(nameCtrl.text.trim(), amountCtrl.text.trim());
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
            Icon(
              Icons.receipt_rounded,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withAlpha((255 * 0.3).round()),
            ),
            Text('No Budgets Yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create a budget to start your journey.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
              ),
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
