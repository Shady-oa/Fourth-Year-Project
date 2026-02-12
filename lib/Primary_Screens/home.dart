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
        // print('this is the userdata');
        //  print(userData);
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
    _refreshData();
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
          tx['type'] == 'savings_deduction') {
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
    _calculateStats();
    setState(() {});
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

  // New method to expose transaction saving for SavingsScreen
  Future<void> _onSavingsTransactionAdded(
    String title,
    double amount,
    String type,
  ) async {
    await _saveTransaction(title, amount, type);
    _refreshData(); // Refresh data to update UI immediately
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
            leading: const Icon(Icons.savings, color: Colors.green),
            title: const Text("Savings Goal"),
            onTap: () {
              Navigator.pop(context);
              _handleSavingsExpense();
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.orange),
            title: const Text("Existing Budget"),
            onTap: () {
              Navigator.pop(context);
              _handleBudgetExpense();
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart, color: Colors.blue),
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
        MaterialPageRoute(builder: (context) => const SavingsScreen()),
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
                  _showAmountDialog(
                    title: "Deduct from ${s.name}",
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

  void _showSavingsOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Text(
            "Savings Options",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ListTile(
            leading: const Icon(
              Icons.account_balance_wallet,
              color: Colors.blue,
            ),
            title: const Text("Go to Savings Page"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SavingsScreen(
                    onTransactionAdded: _onSavingsTransactionAdded,
                  ),
                ),
              ).then((_) => _refreshData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.green),
            title: const Text("Add Funds to Saving Goal"),
            onTap: () {
              Navigator.pop(context);
              if (_savings.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "No saving goals created yet. Create one on the Savings page.",
                    ),
                  ),
                );
              } else {
                _showAddFundsToSavingGoalDialog();
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAddFundsToSavingGoalDialog() {
    final activeSavings = _savings.where((s) => !s.achieved).toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Saving Goal to Add Funds"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: activeSavings.length,
            itemBuilder: (context, index) {
              final s = activeSavings[index];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(
                  "Current Balance: Ksh ${s.savedAmount.toStringAsFixed(2)}",
                ),
                onTap: () {
                  Navigator.pop(context); // Pop the goal selection dialog
                  _showAmountDialog(
                    title: "Add funds to ${s.name}",
                    onConfirm: (amt) async {
                      s.savedAmount += amt;
                      if (s.savedAmount >= s.targetAmount) {
                        s.achieved = true;
                      }
                      await _syncSavings();
                      await _onSavingsTransactionAdded(
                        "Added to ${s.name}",
                        amt,
                        "saving_deposit",
                      );
                      _refreshData(); // Refresh UI after adding funds
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showAmountDialog({
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
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
      decoration: BoxDecoration(borderRadius: radiusLarge, color: brandGreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance', style: TextStyle(color: Colors.white70)),
          Text(
            "Ksh ${balance.toStringAsFixed(0)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          sizedBoxHeightLarge,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem("Income", _totalIncome, Icons.arrow_downward),
              _statItem("Expenses", _totalExpenses, Icons.arrow_upward),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, double amt, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              "Ksh ${amt.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
          label: 'Income',
          onTap: _showAddIncomeDialog,
        ),
        QuickActionCard(
          icon: Icons.remove,
          label: 'Expense',
          onTap: _showSmartExpenseDialog,
        ),
        QuickActionCard(
          icon: Icons.account_balance,
          label: 'Budgets',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BudgetScreen()),
          ).then((_) => _refreshData()),
        ),
        QuickActionCard(
          icon: Icons.savings,
          label: 'Savings',
          onTap: _showSavingsOptionsBottomSheet,
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    if (_transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            "No transactions yet",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length > 10 ? 10 : _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isIncome = tx['type'] == 'income';
        final date = DateTime.parse(tx['date']);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: isIncome
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            child: Icon(
              isIncome ? Icons.add : Icons.remove,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          title: Text(tx['title'] ?? "Unknown"),
          subtitle: Text(DateFormat('dd MMM, hh:mm a').format(date)),
          trailing: Text(
            "${isIncome ? '+' : '-'} Ksh ${tx['amount']}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }
}
