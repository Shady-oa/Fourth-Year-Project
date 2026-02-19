import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Currency Formatter ───────────────────────────────────────────────────────
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');
  static String format(double amount) =>
      'Ksh ${_formatter.format(amount.round())}';
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BUDGET PAGE — Real-time Firestore StreamBuilder
// ═══════════════════════════════════════════════════════════════════════════════
class BudgetPage extends StatefulWidget {
  final Function(String, double, String)? onTransactionAdded;
  final Function(String, double)? onExpenseDeleted;

  const BudgetPage({super.key, this.onTransactionAdded, this.onExpenseDeleted});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  String _filter = 'all';

  // Firestore collection reference
  CollectionReference<Map<String, dynamic>> get _budgetsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('budgets');

  // ── Firestore Helpers ─────────────────────────────────────────────────────
  Future<void> _sendNotification(String title, String message) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? errorColor : brandGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Filtered stream ───────────────────────────────────────────────────────
  Stream<List<Budget>> _budgetStream(String filter) {
    Query<Map<String, dynamic>> query =
        _budgetsRef.orderBy('updatedAt', descending: true);

    return query.snapshots().map((snap) {
      final all = snap.docs
          .map((d) => Budget.fromFirestore(d.id, d.data()))
          .toList();

      if (filter == 'checked') return all.where((b) => b.isChecked).toList();
      if (filter == 'unchecked') return all.where((b) => !b.isChecked).toList();
      return all;
    });
  }

  // ── Create Budget Dialog ──────────────────────────────────────────────────
  void _showCreateBudgetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateBudgetDialog(
        onSubmit: (name, amount) async {
          // Check for duplicates
          final existing = await _budgetsRef
              .where('name', isEqualTo: name)
              .limit(1)
              .get();
          if (existing.docs.isNotEmpty) {
            _showSnack('A budget named "$name" already exists.', isError: true);
            return;
          }

          final data = Budget.newBudgetMap(name, amount);
          await _budgetsRef.add(data);
          await _sendNotification(
            '💼 Budget Created',
            'New budget "$name" created with ${CurrencyFormatter.format(amount)}',
          );
          _showSnack('Budget "$name" created successfully');
        },
      ),
    );
  }

  // ── Options Bottom Sheet ──────────────────────────────────────────────────
  void _showOptionsSheet(Budget budget) {
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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                budget.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
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
              // Edit
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
                        _showEditDialog(budget);
                      },
              ),
              // Delete
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
                  style:
                      TextStyle(fontWeight: FontWeight.w600, color: errorColor),
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

  // ── Edit Dialog ───────────────────────────────────────────────────────────
  void _showEditDialog(Budget budget) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditBudgetDialog(
        budget: budget,
        onSubmit: (name, amount) async {
          await _budgetsRef.doc(budget.id).update({
            'name': name,
            'total': amount,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          _showSnack('Budget updated successfully');
        },
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> _deleteBudget(Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: errorColor, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _budgetsRef.doc(budget.id).delete();
      await _sendNotification(
        '🗑️ Budget Deleted',
        'Budget "${budget.name}" has been deleted',
      );
      _showSnack('Budget deleted successfully');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const CustomHeader(headerName: 'Budgets'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _filterChip('All', 'all', theme),
                const SizedBox(width: 8),
                _filterChip('Finalized', 'checked', theme),
                const SizedBox(width: 8),
                _filterChip('Active', 'unchecked', theme),
              ],
            ),
          ),
          // Live list
          Expanded(
            child: StreamBuilder<List<Budget>>(
              stream: _budgetStream(_filter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading budgets.\nPlease try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                final budgets = snapshot.data ?? [];

                if (budgets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No budgets found',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first budget',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: budgets.length,
                    itemBuilder: (_, i) => _buildCard(budgets[i], theme),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBudgetDialog,
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _filterChip(String label, String value, ThemeData theme) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildCard(Budget budget, ThemeData theme) {
    final totalSpent = budget.totalSpent;
    final amountLeft = budget.amountLeft;
    final progress = (totalSpent / budget.total).clamp(0.0, 1.0);
    final isOverBudget = totalSpent > budget.total;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BudgetDetailPage(
            budgetId: budget.id,
            onBudgetUpdated: () {},
          ),
        ),
      ),
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
            // Header row
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
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
                IconButton(
                  icon: Icon(Icons.more_vert,
                      color: theme.colorScheme.onSurface),
                  onPressed: () => _showOptionsSheet(budget),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Amounts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withAlpha(120)),
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
                          color:
                              theme.colorScheme.onSurface.withAlpha(120)),
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
            // Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Spent: ${CurrencyFormatter.format(totalSpent)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withAlpha(120)),
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

// ═══════════════════════════════════════════════════════════════════════════════
//  CREATE BUDGET DIALOG — isolated widget with loading state
// ═══════════════════════════════════════════════════════════════════════════════
class _CreateBudgetDialog extends StatefulWidget {
  final Future<void> Function(String name, double amount) onSubmit;
  const _CreateBudgetDialog({required this.onSubmit});

  @override
  State<_CreateBudgetDialog> createState() => _CreateBudgetDialogState();
}

class _CreateBudgetDialogState extends State<_CreateBudgetDialog> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text) ?? 0;

    if (name.isEmpty) {
      _snack('Enter a budget name', isError: true);
      return;
    }
    if (amount <= 0) {
      _snack('Enter a valid amount', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onSubmit(name, amount);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? errorColor : brandGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            enabled: !_loading,
            decoration: const InputDecoration(
              labelText: 'Budget Name',
              hintText: 'e.g., Groceries',
              prefixIcon: Icon(Icons.edit),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            enabled: !_loading,
            decoration: const InputDecoration(
              labelText: 'Budget Amount (Ksh)',
              hintText: '0',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EDIT BUDGET DIALOG — isolated widget with loading state
// ═══════════════════════════════════════════════════════════════════════════════
class _EditBudgetDialog extends StatefulWidget {
  final Budget budget;
  final Future<void> Function(String name, double amount) onSubmit;
  const _EditBudgetDialog({required this.budget, required this.onSubmit});

  @override
  State<_EditBudgetDialog> createState() => _EditBudgetDialogState();
}

class _EditBudgetDialogState extends State<_EditBudgetDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.budget.name);
    _amountCtrl =
        TextEditingController(text: widget.budget.total.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text) ?? 0;

    if (name.isEmpty) {
      _snack('Enter a budget name', isError: true);
      return;
    }
    if (amount <= 0) {
      _snack('Enter a valid amount', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onSubmit(name, amount);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? errorColor : brandGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            enabled: !_loading,
            decoration: const InputDecoration(
              labelText: 'Budget Name',
              prefixIcon: Icon(Icons.edit),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            enabled: !_loading,
            decoration: const InputDecoration(
              labelText: 'Budget Amount (Ksh)',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BUDGET MODEL — Firestore-backed
// ═══════════════════════════════════════════════════════════════════════════════
class Budget {
  final String id;
  String name;
  double total;
  List<Expense> expenses;
  bool isChecked;
  DateTime? checkedDate;
  DateTime createdAt;

  Budget({
    required this.id,
    required this.name,
    required this.total,
    List<Expense>? expenses,
    this.isChecked = false,
    this.checkedDate,
    DateTime? createdAt,
  })  : expenses = expenses ?? [],
        createdAt = createdAt ?? DateTime.now();

  double get totalSpent => expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get amountLeft => total - totalSpent;

  /// Builds a fresh Firestore document map for a new budget.
  static Map<String, dynamic> newBudgetMap(String name, double amount) => {
        'name': name,
        'total': amount,
        'expenses': [],
        'isChecked': false,
        'checkedDate': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'total': total,
        'expenses': expenses.map((e) => e.toMap()).toList(),
        'isChecked': isChecked,
        'checkedDate': checkedDate?.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory Budget.fromFirestore(String docId, Map<String, dynamic> map) {
    return Budget(
      id: docId,
      name: map['name'] ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0,
      expenses: (map['expenses'] as List?)
              ?.map((e) => Expense.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      isChecked: map['isChecked'] ?? false,
      checkedDate: map['checkedDate'] != null
          ? DateTime.tryParse(map['checkedDate'])
          : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EXPENSE MODEL
// ═══════════════════════════════════════════════════════════════════════════════
class Expense {
  final String id;
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
        name: map['name'] ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        createdDate: map['createdDate'] != null
            ? DateTime.tryParse(map['createdDate']) ?? DateTime.now()
            : DateTime.now(),
      );
}