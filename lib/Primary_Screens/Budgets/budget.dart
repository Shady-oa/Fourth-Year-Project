import 'dart:convert';

import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
// Note: The Budget class is defined at the bottom of this file.
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => BudgetScreenState();
}

enum BudgetFilter { all, active, achieved }

// Public State Class
class BudgetScreenState extends State<BudgetScreen> {
  // Public Variables
  List<Budget> budgets = [];
  BudgetFilter currentFilter = BudgetFilter.all;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  // -------------------- Public Helpers --------------------

  String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'Ksh ',
      decimalDigits: 2,
    ).format(amount);
  }

  List<Budget> get filteredBudgets {
    switch (currentFilter) {
      case BudgetFilter.active:
        return budgets.where((b) => !b.achieved).toList();
      case BudgetFilter.achieved:
        return budgets.where((b) => b.achieved).toList();
      case BudgetFilter.all:
        return budgets;
    }
  }

  // -------------------- Public Persistence --------------------

  Future<void> loadBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetStrings = prefs.getStringList('budgets') ?? [];

      final List<Budget> loadedBudgets = [];

      for (var str in budgetStrings) {
        try {
          final dynamic decoded = json.decode(str);
          loadedBudgets.add(Budget.fromMap(decoded));
        } catch (e) {
          debugPrint("Skipping corrupted budget data: $e");
        }
      }

      setState(() {
        budgets = loadedBudgets;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading budgets: $e");
      setState(() {
        budgets = [];
        isLoading = false;
      });
    }
  }

  Future<void> saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = budgets.map((b) => json.encode(b.toMap())).toList();
    await prefs.setStringList('budgets', data);
  }

  // -------------------- Public Actions --------------------

  void addBudget(String name, double amount) {
    setState(() {
      budgets.add(Budget(name: capitalizeWords(name), total: amount));
    });
    saveBudgets();
    Fluttertoast.showToast(msg: 'Budget for $name added.');
  }

  void addMoney(int index, double amount) {
    setState(() {
      budgets[index].total += amount;
    });
    saveBudgets();
    Fluttertoast.showToast(
      msg: 'Added ${formatCurrency(amount)} to ${budgets[index].name}',
    );
  }

  void updateAvatar(Budget budget, String newIconCode) {
    setState(() {
      budget.iconCode = newIconCode;
    });
    saveBudgets();
  }

  void deleteBudget(Budget budget) {
    setState(() => budgets.remove(budget));
    saveBudgets();
    Fluttertoast.showToast(msg: 'Budget for ${budget.name} deleted');
  }

  void renameBudget(Budget budget, String newName) {
    setState(() {
      budget.name = capitalizeWords(newName);
    });
    saveBudgets();
    Fluttertoast.showToast(msg: 'Budget renamed to ${budget.name}');
  }

  void toggleAchieved(Budget budget) {
    setState(() {
      budget.achieved = !budget.achieved;
    });
    saveBudgets();
    Fluttertoast.showToast(
      msg: budget.achieved ? 'Marked as achieved' : 'Marked as active',
    );
  }

  // -------------------- Public UI Methods --------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayedBudgets = filteredBudgets;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: CustomHeader(headerName: "Budgets"),
      ),
      body: Column(
        children: [
          // Filter Section
          if (budgets.isNotEmpty) buildFilterBar(theme),

          // Main Content
          Expanded(
            child: budgets.isEmpty
                ? buildEmptyState(theme)
                : displayedBudgets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.unpublished_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text("No ${currentFilter.name} budgets found"),
                      ],
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: displayedBudgets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return buildBudgetCard(theme, displayedBudgets[index]);
                      },
                    ),
                  ),
          ),

          // Bottom Add Button (Only if list is not empty)
          if (budgets.isNotEmpty) buildAddAnotherButton(theme),
        ],
      ),
    );
  }

  Widget buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: SegmentedButton<BudgetFilter>(
        segments: const [
          ButtonSegment(
            value: BudgetFilter.all,
            label: Text('All'),
            icon: Icon(Icons.list),
          ),
          ButtonSegment(value: BudgetFilter.active, label: Text('Active')),
          ButtonSegment(value: BudgetFilter.achieved, label: Text('Achieved')),
        ],
        selected: {currentFilter},
        onSelectionChanged: (Set<BudgetFilter> newSelection) {
          setState(() {
            currentFilter = newSelection.first;
          });
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget buildBudgetCard(ThemeData theme, Budget budget) {
    return Container(
      decoration: BoxDecoration(
        color: budget.achieved
            ? theme.colorScheme.surfaceVariant.withOpacity(0.5)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: budget.achieved
              ? Colors.green.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showBudgetOptions(budget),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: budget.achieved
                      ? Colors.green.withOpacity(0.2)
                      : theme.colorScheme.primaryContainer,
                  backgroundImage: Image.asset("assets/image/icon 2.png").image,
                ),

                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,

                          color: budget.achieved
                              ? theme.textTheme.bodyMedium?.color?.withOpacity(
                                  0.6,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency(budget.total),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: budget.achieved
                              ? Colors.green
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: Colors.grey,
                  onPressed: () => showBudgetOptions(budget),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAddAnotherButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: GestureDetector(
        onTap: showAddBudgetDialog,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Add Another Budget',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }

  Widget buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_rounded,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            Text('No Budgets Yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create a budget to start tracking your expenses.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: showAddBudgetDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Create Your First Budget',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showBudgetOptions(Budget budget) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(budget.name, style: Theme.of(context).textTheme.titleLarge),
              const Divider(height: 30),
              optionTile(Icons.add_circle_outline, 'Add Funds', () {
                Navigator.pop(context);
                final index = budgets.indexOf(budget);
                if (index != -1) showAddMoneyDialog(index);
              }),
              optionTile(Icons.edit_outlined, 'Rename Budget', () {
                Navigator.pop(context);
                showRenameBudgetDialog(budget);
              }),
              optionTile(
                budget.achieved
                    ? Icons.unpublished_outlined
                    : Icons.check_circle_outline,
                budget.achieved ? 'Mark as Active' : 'Mark as Achieved',
                () {
                  Navigator.pop(context);
                  toggleAchieved(budget);
                },
              ),
              const Divider(),
              optionTile(Icons.delete_outline, 'Delete Budget', () {
                Navigator.pop(context);
                showDeleteConfirmationDialog(budget);
              }, destructive: true),
            ],
          ),
        );
      },
    );
  }

  Widget optionTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    final color = destructive ? Colors.red : null;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (destructive ? Colors.red : Theme.of(context).primaryColor)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      ),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  void showAddBudgetDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Budget Name',
                prefixIcon: Icon(Icons.label),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text;
              final amount = double.tryParse(amountController.text) ?? 0;
              if (name.isNotEmpty && amount > 0) {
                addBudget(name, amount);
                Navigator.pop(context);
              } else {
                Fluttertoast.showToast(msg: 'Please check your input');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void showAddMoneyDialog(int index) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Money'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount to add',
            prefixIcon: Icon(Icons.add),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                addMoney(index, amount);
                Navigator.pop(context);
              } else {
                Fluttertoast.showToast(msg: 'Invalid amount');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void showDeleteConfirmationDialog(Budget budget) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: Text('Are you sure you want to delete "${budget.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              deleteBudget(budget);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void showRenameBudgetDialog(Budget budget) {
    final controller = TextEditingController(text: budget.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Budget'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                renameBudget(budget, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

// -------------------- ROBUST BUDGET MODEL --------------------

class Budget {
  String name;
  double total;
  bool achieved;
  String? iconCode;

  Budget({
    required this.name,
    required this.total,
    this.achieved = false,
    this.iconCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'total': total,
      'achieved': achieved,
      'iconCode': iconCode,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      name: map['name'] ?? 'Unnamed',
      // SAFELY HANDLE String OR Number for 'total' to prevent Red Screen
      total: map['total'] is String
          ? double.tryParse(map['total']) ?? 0.0
          : (map['total'] as num?)?.toDouble() ?? 0.0,
      achieved: map['achieved'] ?? false,
      iconCode: map['iconCode'],
    );
  }
}
