import 'dart:convert';

import 'package:final_project/Components/Custom_header.dart';
// Note: The Budget class is defined at the bottom of this file to prevent conflicts.
// Do not import the old model file.
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

enum BudgetFilter { all, active, achieved }

class _BudgetScreenState extends State<BudgetScreen> {
  List<Budget> _budgets = [];
  BudgetFilter _currentFilter = BudgetFilter.all;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  // -------------------- Helpers --------------------

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'Ksh ',
      decimalDigits: 0,
    ).format(amount);
  }

  List<Budget> get _filteredBudgets {
    switch (_currentFilter) {
      case BudgetFilter.active:
        return _budgets.where((b) => !b.achieved).toList();
      case BudgetFilter.achieved:
        return _budgets.where((b) => b.achieved).toList();
      case BudgetFilter.all:
      default:
        return _budgets;
    }
  }

  // -------------------- Persistence (FIXED) --------------------

  Future<void> _loadBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetStrings = prefs.getStringList('budgets') ?? [];

      final List<Budget> loadedBudgets = [];

      for (var str in budgetStrings) {
        try {
          // We try-catch individual items so one bad apple doesn't crash the app
          final dynamic decoded = json.decode(str);
          loadedBudgets.add(Budget.fromMap(decoded));
        } catch (e) {
          debugPrint("Skipping corrupted budget data: $e");
        }
      }

      setState(() {
        _budgets = loadedBudgets;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading budgets: $e");
      // If everything fails, start with empty list to prevent red screen
      setState(() {
        _budgets = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _budgets.map((b) => json.encode(b.toMap())).toList();
    await prefs.setStringList('budgets', data);
  }

  // -------------------- Actions --------------------

  void _addBudget(String name, double amount) {
    setState(() {
      _budgets.add(Budget(name: _capitalizeWords(name), total: amount));
    });
    _saveBudgets();
    Fluttertoast.showToast(msg: 'Budget added');
  }

  void _addMoney(int index, double amount) {
    setState(() {
      _budgets[index].total += amount;
    });
    _saveBudgets();
    Fluttertoast.showToast(
      msg: 'Added ${_formatCurrency(amount)} to ${_budgets[index].name}',
    );
  }

  void _updateAvatar(Budget budget, String newIconCode) {
    setState(() {
      budget.iconCode = newIconCode;
    });
    _saveBudgets();
  }

  void _deleteBudget(Budget budget) {
    setState(() => _budgets.remove(budget));
    _saveBudgets();
    Fluttertoast.showToast(msg: 'Budget deleted');
  }

  void _renameBudget(Budget budget, String newName) {
    setState(() {
      budget.name = _capitalizeWords(newName);
    });
    _saveBudgets();
    Fluttertoast.showToast(msg: 'Budget renamed to ${budget.name}');
  }

  void _toggleAchieved(Budget budget) {
    setState(() {
      budget.achieved = !budget.achieved;
    });
    _saveBudgets();
    Fluttertoast.showToast(
      msg: budget.achieved ? 'Marked as achieved' : 'Marked as active',
    );
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayedBudgets = _filteredBudgets;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: CustomHeader(headerName: "Budgets"),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Section
          if (_budgets.isNotEmpty) _buildFilterBar(theme),

          // Main Content
          Expanded(
            child: _budgets.isEmpty
                ? _buildEmptyState(theme)
                : displayedBudgets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text("No ${_currentFilter.name} budgets found"),
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
                        return _buildBudgetCard(theme, displayedBudgets[index]);
                      },
                    ),
                  ),
          ),

          // Bottom Add Button
          if (_budgets.isNotEmpty) _buildAddAnotherButton(theme),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        selected: {_currentFilter},
        onSelectionChanged: (Set<BudgetFilter> newSelection) {
          setState(() {
            _currentFilter = newSelection.first;
          });
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildBudgetCard(ThemeData theme, Budget budget) {
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
          onTap: () => _showBudgetOptions(budget),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Custom Avatar
                GestureDetector(
                  onTap: () => _showAvatarPicker(budget),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: budget.achieved
                        ? Colors.green.withOpacity(0.2)
                        : theme.colorScheme.primaryContainer,
                    child: Text(
                      budget.iconCode ?? '💰',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: budget.achieved
                              ? TextDecoration.lineThrough
                              : null,
                          color: budget.achieved
                              ? theme.textTheme.bodyMedium?.color?.withOpacity(
                                  0.6,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(budget.total),
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

                // Option Menu Icon
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: Colors.grey,
                  onPressed: () => _showBudgetOptions(budget),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddAnotherButton(ThemeData theme) {
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
        onTap: _showAddBudgetDialog,
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
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_outlined,
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
            ElevatedButton.icon(
              onPressed: _showAddBudgetDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create First Budget'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- Avatars --------------------

  void _showAvatarPicker(Budget budget) {
    final List<String> icons = [
      '💰',
      '🏠',
      '🚗',
      '🍔',
      '✈️',
      '🎮',
      '👕',
      '🏥',
      '🎓',
      '📱',
      '💼',
      '🛒',
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choose Avatar'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: icons.map((icon) {
              return GestureDetector(
                onTap: () {
                  _updateAvatar(budget, icon);
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // -------------------- Bottom Sheet & Dialogs --------------------

  void _showBudgetOptions(Budget budget) {
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
              _optionTile(Icons.add_circle_outline, 'Add Funds', () {
                Navigator.pop(context);
                final index = _budgets.indexOf(budget);
                if (index != -1) _showAddMoneyDialog(index);
              }),
              _optionTile(Icons.edit_outlined, 'Rename Budget', () {
                Navigator.pop(context);
                _showRenameBudgetDialog(budget);
              }),
              _optionTile(
                budget.achieved
                    ? Icons.unpublished_outlined
                    : Icons.check_circle_outline,
                budget.achieved ? 'Mark as Active' : 'Mark as Achieved',
                () {
                  Navigator.pop(context);
                  _toggleAchieved(budget);
                },
              ),
              const Divider(),
              _optionTile(Icons.delete_outline, 'Delete Budget', () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(budget);
              }, destructive: true),
            ],
          ),
        );
      },
    );
  }

  Widget _optionTile(
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

  void _showAddBudgetDialog() {
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
                _addBudget(name, amount);
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

  void _showAddMoneyDialog(int index) {
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
                _addMoney(index, amount);
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

  void _showDeleteConfirmationDialog(Budget budget) {
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
              _deleteBudget(budget);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRenameBudgetDialog(Budget budget) {
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
                _renameBudget(budget, controller.text);
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
