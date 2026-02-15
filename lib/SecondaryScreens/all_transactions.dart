import 'dart:convert';

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  List<Map<String, dynamic>> _transactions = [];
  String _filter = 'all'; // all, income, expense
  bool _isLoading = true;
  double _totalIncome = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final txString = prefs.getString('recent_transactions') ?? '[]';
    _transactions = List<Map<String, dynamic>>.from(json.decode(txString));
    _totalIncome = prefs.getDouble('total_income') ?? 0.0;
    setState(() => _isLoading = false);
  }

  // NEW: Delete transaction method
  Future<void> _deleteTransaction(int originalIndex) async {
    // Find the transaction in the original list
    final tx = _transactions[originalIndex];
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final type = tx['type'];

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete this transaction?'),
            const SizedBox(height: 12),
            Text(
              '${tx['title']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Amount: Ksh ${amount.toStringAsFixed(0)}'),
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
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will affect your balance and statistics.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Remove transaction from list
      _transactions.removeAt(originalIndex);

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recent_transactions', json.encode(_transactions));

      // Update total income if it was an income transaction
      if (type == 'income') {
        _totalIncome -= amount;
        await prefs.setDouble('total_income', _totalIncome);
      }

      // Update UI
      setState(() {});

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted successfully'),
            backgroundColor: brandGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_filter == 'all') return _transactions;
    if (_filter == 'income') {
      return _transactions.where((tx) => tx['type'] == 'income').toList();
    }
    // expense filter
    return _transactions.where((tx) => tx['type'] != 'income').toList();
  }

  // Group transactions by date
  Map<String, List<Map<String, dynamic>>> get _groupedTransactions {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var tx in _filteredTransactions) {
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
    final groupedTx = _groupedTransactions;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text("All Transactions"),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all', theme),
                      const SizedBox(width: 8),
                      _buildFilterChip('Income', 'income', theme),
                      const SizedBox(width: 8),
                      _buildFilterChip('Expenses', 'expense', theme),
                    ],
                  ),
                ),

                // Summary Card
                _buildSummaryCard(theme),

                // Transactions List
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions found',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: groupedTx.length,
                          itemBuilder: (context, index) {
                            final dateKey = groupedTx.keys.elementAt(index);
                            final txList = groupedTx[dateKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                  child: Text(
                                    _getDateLabel(dateKey),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface.withAlpha(80),
                                        ),
                                  ),
                                ),

                                // Transaction Cards
                                ...txList.map((tx) {
                                  // Find original index in _transactions list
                                  final originalIndex = _transactions.indexOf(
                                    tx,
                                  );
                                  return _buildTransactionCard(
                                    tx,
                                    originalIndex,
                                    theme,
                                  );
                                }),

                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
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

  Widget _buildSummaryCard(ThemeData theme) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var tx in _filteredTransactions) {
      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
      if (tx['type'] == 'income') {
        totalIncome += amount;
      } else {
        totalExpense += amount;
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
          _buildSummaryStat(
            'Income',
            totalIncome,
            Icons.arrow_circle_down_rounded,
            theme.colorScheme.onSurface,
          ),
          Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
          _buildSummaryStat(
            'Expenses',
            totalExpense,
            Icons.arrow_circle_up_rounded,
            theme.colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
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
          'Ksh ${amount.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> tx,
    int originalIndex,
    ThemeData theme,
  ) {
    final isIncome = tx['type'] == 'income';
    final date = DateTime.parse(tx['date']);
    final time = DateFormat('hh:mm a').format(date);
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;

    // Get icon based on transaction type
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
      case 'savings_deduction':
      case 'saving_deposit':
        txIcon = Icons.savings;
        iconBgColor = brandGreen;
        break;
      default:
        txIcon = Icons.arrow_circle_up_outlined;
        iconBgColor = errorColor;
    }

    return Dismissible(
      key: Key('${tx['date']}_$originalIndex'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        // This will be handled by the delete method which shows the dialog
        await _deleteTransaction(originalIndex);
        return false; // Always return false because we handle deletion manually
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(txIcon, color: iconBgColor, size: 30),
          ),
          title: Text(
            tx['title'] ?? "Unknown",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
              ),
              const SizedBox(width: 4),
              Text(
                time,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getTypeLabel(tx['type']),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: iconBgColor),
                ),
              ),
              Text(
                "${isIncome ? '+' : '-'} Ksh ${amount.toStringAsFixed(0)}",
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

  String _getDateLabel(String dateKey) {
    final date = DateFormat('dd MMM yyyy').parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return 'Today';
    } else if (txDate == yesterday) {
      return 'Yesterday';
    } else {
      return dateKey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Income';
      case 'budget_expense':
        return 'Budget';
      case 'savings_deduction':
      case 'saving_deposit':
        return 'Savings';
      case 'expense':
        return 'Expense';
      default:
        return 'Other';
    }
  }
}
