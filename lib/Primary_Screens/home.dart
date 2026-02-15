import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Components/quick_actions.dart';
import 'package:final_project/Components/them_toggle.dart';
// Import project constants and components
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
// Import Screens
import 'package:final_project/Primary_Screens/Budgets/budget.dart';
import 'package:final_project/Primary_Screens/Savings/savings.dart';
import 'package:final_project/SecondaryScreens/all_transactions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Persistence Keys
  static const String keyTransactions = 'recent_transactions';
  static const String keyBudgets = 'budgets';
  static const String keySavings = 'savings';
  static const String keyTotalIncome = 'total_income';
  final userUid = FirebaseAuth.instance.currentUser!.uid;
  final usersDB = FirebaseFirestore.instance.collection('users');
  String? username;
  String? profileImage;
  StreamSubscription? userSubscription;

  void loadData() async {
    userSubscription = usersDB.doc(userUid).snapshots().listen((snapshots) {
      if (snapshots.exists) {
        final userData = snapshots.data() as Map<String, dynamic>;
        setState(() {
          username = userData['username'] ?? '';
          profileImage = userData['profileUrl'] ?? '';
        });
      }
    });
  }

  List<Map<String, dynamic>> _transactions = [];
  List<Budget> _budgets = [];
  List<Saving> _savings = [];

  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
    _refreshData();
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    super.dispose();
  }

  // --- DATA PERSISTENCE ---

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    // Load Transactions
    final txString = prefs.getString(keyTransactions) ?? '[]';
    _transactions = List<Map<String, dynamic>>.from(json.decode(txString));

    // Load Budgets
    final budgetStrings = prefs.getStringList(keyBudgets) ?? [];
    _budgets = budgetStrings
        .map((s) => Budget.fromMap(json.decode(s)))
        .toList();

    // Load Savings
    final savingsStrings = prefs.getStringList(keySavings) ?? [];
    _savings = savingsStrings
        .map((s) => Saving.fromMap(json.decode(s)))
        .toList();

    // Load Income
    _totalIncome = prefs.getDouble(keyTotalIncome) ?? 0.0;

    _calculateStats();
    setState(() => _isLoading = false);
  }

  void _calculateStats() {
    double expenses = 0.0;
    for (var tx in _transactions) {
      if (tx['type'] == 'expense' ||
          tx['type'] == 'budget_expense' ||
          tx['type'] == 'savings_deduction' ||
          tx['type'] == 'saving_deposit') {
        expenses += double.tryParse(tx['amount'].toString()) ?? 0.0;
      }
    }
    _totalExpenses = expenses;
  }

  Future<void> _saveTransaction(
    String title,
    double amount,
    String type,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final newTx = {
      'title': title,
      'amount': amount,
      'type': type,
      'date': DateTime.now().toIso8601String(),
    };
    _transactions.insert(0, newTx);
    await prefs.setString(keyTransactions, json.encode(_transactions));
    debugPrint('💾 Transaction saved: $title, $amount, $type');
    debugPrint('📊 Total transactions: ${_transactions.length}');
    _calculateStats();
    setState(() {});

    // Show informative toast
    _showTransactionToast(type, amount);
  }

  // NEW: Show toast notification after adding transaction
  void _showTransactionToast(String type, double amount) {
    final isIncome = type == 'income';
    final icon = isIncome ? '💰' : '💸';
    final action = isIncome ? 'Income Added' : 'Expense Recorded';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$action: Ksh ${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '💡 Tip: Swipe left or right to delete transactions',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: isIncome ? brandGreen : Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // NEW: Delete transaction method
  Future<void> _deleteTransaction(int index) async {
    final tx = _transactions[index];
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
            const Text('Are you sure you want to delete this transaction?'),
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
      _transactions.removeAt(index);

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyTransactions, json.encode(_transactions));

      // Update total income if it was an income transaction
      if (type == 'income') {
        _totalIncome -= amount;
        await prefs.setDouble(keyTotalIncome, _totalIncome);
      }

      // Recalculate statistics
      _calculateStats();

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

      debugPrint('🗑️ Transaction deleted: ${tx['title']}');
    }
  }

  Future<void> _syncBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _budgets.map((b) => json.encode(b.toMap())).toList();
    await prefs.setStringList(keyBudgets, data);
  }

  Future<void> _syncSavings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _savings.map((s) => json.encode(s.toMap())).toList();
    await prefs.setStringList(keySavings, data);
  }

  // Method to expose transaction saving for SavingsScreen
  Future<void> _onSavingsTransactionAdded(
    String title,
    double amount,
    String type,
  ) async {
    debugPrint(
      '🔔 Callback received from SavingsScreen: $title, $amount, $type',
    );
    await _saveTransaction(title, amount, type);
    await _refreshData(); // Refresh data to update UI immediately
    debugPrint('✨ Home page refreshed');
  }

  // --- DIALOGS & LOGIC ---

  void _showAddIncomeDialog() {
    final amountController = TextEditingController();
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Income"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                hintText: "Source (e.g. Salary)",
              ),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Amount (Ksh)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amountController.text) ?? 0;
              if (amt > 0 && titleCtrl.text.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                _totalIncome += amt;
                await prefs.setDouble(keyTotalIncome, _totalIncome);
                await _saveTransaction(titleCtrl.text, amt, "income");
                Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showSmartExpenseDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Text("Expense for?", style: Theme.of(context).textTheme.titleLarge),
          ListTile(
            leading: const Icon(Icons.savings, color: brandGreen),
            title: const Text("Savings Goal"),
            onTap: () {
              Navigator.pop(context);
              _handleSavingsExpense();
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_rounded, color: Colors.orange),
            title: const Text("Existing Budget"),
            onTap: () {
              Navigator.pop(context);
              _handleBudgetExpense();
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.arrow_circle_up_rounded,
              color: errorColor,
            ),
            title: const Text("Other Expense"),
            onTap: () {
              Navigator.pop(context);
              _showGeneralExpenseDialog();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- SAVINGS LOGIC ---
  void _handleSavingsExpense() {
    final activeSavings = _savings.where((s) => !s.achieved).toList();
    if (activeSavings.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SavingsScreen(onTransactionAdded: _onSavingsTransactionAdded),
        ),
      ).then((_) => _refreshData());
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Savings Goal"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: activeSavings.length,
            itemBuilder: (context, index) {
              final s = activeSavings[index];
              return ListTile(
                title: Text(s.name),
                subtitle: Text("Balance: Ksh ${s.balance}"),
                onTap: () {
                  Navigator.pop(context);
                  showAmountDialog(
                    title: "Add funds to ${s.name}",
                    onConfirm: (amt) async {
                      s.savedAmount += amt;
                      if (s.savedAmount >= s.targetAmount) {
                        s.achieved = true;
                      }
                      await _syncSavings();
                      await _saveTransaction(
                        "Saved for ${s.name}",
                        amt,
                        "savings_deduction",
                      );
                      _refreshData();
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // --- BUDGET LOGIC ---
  void _handleBudgetExpense() {
    if (_budgets.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BudgetScreen()),
      ).then((_) => _refreshData());
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Budget"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _budgets.length,
            itemBuilder: (context, index) {
              final b = _budgets[index];
              return ListTile(
                title: Text(b.name),
                onTap: () {
                  Navigator.pop(context);
                  _showBudgetDetailEntryDialog(b);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBudgetDetailEntryDialog(Budget budget) {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Expense for ${budget.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(hintText: "Title (e.g. Lunch)"),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Amount"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text) ?? 0;
              if (amt > 0 && titleCtrl.text.isNotEmpty) {
                budget.expenses.add(Expense(name: titleCtrl.text, amount: amt));
                await _syncBudgets();
                await _saveTransaction(
                  "${budget.name}: ${titleCtrl.text}",
                  amt,
                  "budget_expense",
                );
                Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- OTHER EXPENSE ---
  void _showGeneralExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Other Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(hintText: "What was it for?"),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Amount"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(amtCtrl.text) ?? 0;
              if (amt > 0 && titleCtrl.text.isNotEmpty) {
                await _saveTransaction(titleCtrl.text, amt, "expense");
                Navigator.pop(context);
                _refreshData();
              }
            },
            child: const Text("Deduct"),
          ),
        ],
      ),
    );
  }

  void showAmountDialog({
    required String title,
    required Function(double) onConfirm,
  }) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text) ?? 0;
              if (val > 0) {
                onConfirm(val);
                Navigator.pop(context);
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    String greetings() {
      final int hour = DateTime.now().hour;
      if (hour < 12) {
        return 'Good Morning';
      } else if (hour < 17) {
        return 'Good Afternoon';
      } else {
        return 'Good Evening';
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: Row(
          children: [
            SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundImage: (profileImage == null)
                  ? AssetImage("assets/image/icon.png")
                  : NetworkImage(profileImage!),
            ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greetings(), style: Theme.of(context).textTheme.headlineSmall),
            Text(
              username ?? 'Penny User',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: paddingAllTiny,
            child: Row(children: [const ThemeToggleIcon(), NotificationIcon()]),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: paddingAllMedium,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    sizedBoxHeightLarge,
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    sizedBoxHeightSmall,
                    _buildQuickActions(),
                    sizedBoxHeightLarge,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    _buildRecentTransactions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    double balance = _totalIncome - _totalExpenses;
    return Container(
      width: double.infinity,
      padding: paddingAllMedium,
      decoration: BoxDecoration(
        borderRadius: radiusSmall,
        color: balance < 0 ? errorColor : accentColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            "Ksh ${balance.toStringAsFixed(0)}",
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem(
                "Income",
                _totalIncome,
                Icons.arrow_circle_down_rounded,
              ),
              _statItem(
                "Expenses",
                _totalExpenses,
                Icons.arrow_circle_up_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, double amt, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
          size: 30,
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              "Ksh ${amt.toStringAsFixed(0)}",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        QuickActionCard(
          icon: Icons.add,
          label: 'Add Income',
          onTap: _showAddIncomeDialog,
        ),
        QuickActionCard(
          icon: Icons.remove,
          label: 'Expense',
          onTap: _showSmartExpenseDialog,
        ),
        QuickActionCard(
          icon: Icons.receipt_long,
          label: 'All Trans.',
          onTap: () async {
            // Navigate and refresh on return
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AllTransactionsPage(),
              ),
            );
            // Refresh data when coming back from All Transactions
            _refreshData();
          },
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    if (_transactions.isEmpty) {
      return Center(
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // Show only first 8 transactions
    final displayTransactions = _transactions.length > 8
        ? _transactions.sublist(0, 8)
        : _transactions;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayTransactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionCard(displayTransactions[index], index);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, int index) {
    final theme = Theme.of(context);
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
      key: Key('${tx['date']}_$index'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        // This will be handled by the delete method which shows the dialog
        await _deleteTransaction(index);
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
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isIncome ? brandGreen : errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
