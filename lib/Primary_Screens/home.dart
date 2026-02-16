import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Components/quick_actions.dart';
import 'package:final_project/Components/them_toggle.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/Budgets/budget.dart';
import 'package:final_project/Primary_Screens/Savings/savings.dart';
import 'package:final_project/SecondaryScreens/all_transactions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Currency formatting utility
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');
  static String format(double amount) =>
      'Ksh ${_formatter.format(amount.round())}';
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String keyTransactions = 'transactions';
  static const String keyBudgets = 'budgets';
  static const String keySavings = 'savings';
  static const String keyTotalIncome = 'total_income';
  static const String keyStreakCount = 'streak_count';
  static const String keyLastSaveDate = 'last_save_date';
  static const String keyStreakLevel = 'streak_level';

  final userUid = FirebaseAuth.instance.currentUser!.uid;
  final usersDB = FirebaseFirestore.instance.collection('users');
  String? username;
  String? profileImage;
  StreamSubscription? userSubscription;

  List<Map<String, dynamic>> transactions = [];
  List<Budget> budgets = [];
  List<Saving> savings = [];

  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
    refreshData();
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    super.dispose();
  }

  void loadUserData() async {
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

  Future<void> refreshData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    final txString = prefs.getString(keyTransactions) ?? '[]';
    transactions = List<Map<String, dynamic>>.from(json.decode(txString));

    final budgetStrings = prefs.getStringList(keyBudgets) ?? [];
    budgets = budgetStrings.map((s) => Budget.fromMap(json.decode(s))).toList();

    final savingsStrings = prefs.getStringList(keySavings) ?? [];
    savings = savingsStrings
        .map((s) => Saving.fromMap(json.decode(s)))
        .toList();

    totalIncome = prefs.getDouble(keyTotalIncome) ?? 0.0;

    checkSavingsDeadlines();
    calculateStats();
    setState(() => isLoading = false);
  }

  void calculateStats() {
    double expenses = 0.0;
    for (var tx in transactions) {
      if (tx['type'] == 'expense' ||
          tx['type'] == 'budget_finalized' ||
          tx['type'] == 'savings_deduction' ||
          tx['type'] == 'saving_deposit') {
        expenses += double.tryParse(tx['amount'].toString()) ?? 0.0;
      }
    }
    totalExpenses = expenses;
  }

  Future<void> saveTransaction(String title, double amount, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final newTx = {
      'title': title,
      'amount': amount,
      'type': type,
      'date': DateTime.now().toIso8601String(),
    };
    transactions.insert(0, newTx);
    await prefs.setString(keyTransactions, json.encode(transactions));
    calculateStats();
    setState(() {});
    showTransactionToast(type, amount);
  }

  void showTransactionToast(String type, double amount) {
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
                    '$action: ${CurrencyFormatter.format(amount)}',
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

  /// Check if a transaction belongs to an achieved saving goal
  bool isTransactionLinkedToAchievedGoal(Map<String, dynamic> tx) {
    if (tx['type'] != 'savings_deduction' && tx['type'] != 'saving_deposit') {
      return false;
    }

    final title = tx['title'] ?? '';

    for (var saving in savings) {
      if (title.contains(saving.name) && saving.achieved) {
        return true;
      }
    }

    return false;
  }

  /// Check if a transaction belongs to a finalized/checked budget
  bool isTransactionLinkedToCheckedBudget(Map<String, dynamic> tx) {
    if (tx['type'] != 'budget_finalized') {
      return false;
    }

    final budgetId = tx['budgetId'];
    if (budgetId == null) return false;

    for (var budget in budgets) {
      if (budget.id == budgetId && budget.isChecked) {
        return true;
      }
    }

    return false;
  }

  /// Recalculate savings goals after transaction deletion (system-level safety)
  Future<void> recalculateSavingsGoals() async {
    final prefs = await SharedPreferences.getInstance();

    final txString = prefs.getString(keyTransactions) ?? '[]';
    final currentTransactions = List<Map<String, dynamic>>.from(
      json.decode(txString),
    );

    bool savingsChanged = false;

    for (var saving in savings) {
      double calculatedAmount = 0.0;

      for (var tx in currentTransactions) {
        if ((tx['type'] == 'savings_deduction' ||
                tx['type'] == 'saving_deposit') &&
            tx['title'] != null &&
            tx['title'].toString().contains('Saved for ${saving.name}')) {
          calculatedAmount += double.tryParse(tx['amount'].toString()) ?? 0.0;
        }
      }

      if (saving.savedAmount != calculatedAmount) {
        saving.savedAmount = calculatedAmount;
        savingsChanged = true;
      }

      // Dynamically calculate achieved status
      bool shouldBeAchieved = saving.savedAmount >= saving.targetAmount;
      if (saving.achieved != shouldBeAchieved) {
        saving.achieved = shouldBeAchieved;
        savingsChanged = true;
        debugPrint(
          '🔄 Saving goal "${saving.name}" status changed: Achieved=$shouldBeAchieved',
        );
      }
    }

    if (savingsChanged) {
      final data = savings.map((s) => json.encode(s.toMap())).toList();
      await prefs.setStringList(keySavings, data);
      debugPrint('✅ Savings goals recalculated and persisted');
    }
  }

  Future<void> deleteTransaction(int index) async {
    final tx = transactions[index];
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final type = tx['type'];

    // BUSINESS RULE: Check if transaction is linked to an achieved saving goal
    if (isTransactionLinkedToAchievedGoal(tx)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.lock, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transactions linked to an achieved saving goal cannot be deleted.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      return; // Prevent deletion
    }

    // BUSINESS RULE: Check if transaction is linked to a finalized budget
    if (isTransactionLinkedToCheckedBudget(tx)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.lock, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transactions from finalized budgets cannot be deleted.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      return; // Prevent deletion
    }

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
            Text('Amount: ${CurrencyFormatter.format(amount)}'),
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
      transactions.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyTransactions, json.encode(transactions));

      if (type == 'income') {
        totalIncome -= amount;
        await prefs.setDouble(keyTotalIncome, totalIncome);
      }

      // CRITICAL: Recalculate savings goals after deletion
      await recalculateSavingsGoals();

      calculateStats();
      setState(() {});

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

  Future<void> syncBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = budgets.map((b) => json.encode(b.toMap())).toList();
    await prefs.setStringList(keyBudgets, data);
  }

  Future<void> syncSavings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = savings.map((s) => json.encode(s.toMap())).toList();
    await prefs.setStringList(keySavings, data);
  }

  Future<void> onSavingsTransactionAdded(
    String title,
    double amount,
    String type,
  ) async {
    await saveTransaction(title, amount, type);
    await updateStreak();
    await refreshData();
  }

  Future<void> onBudgetTransactionAdded(
    String title,
    double amount,
    String type,
  ) async {
    await saveTransaction(title, amount, type);
    await refreshData();
  }

  Future<void> onBudgetExpenseDeleted(String title, double amount) async {
    transactions.removeWhere(
      (tx) =>
          tx['title'] == title &&
          double.tryParse(tx['amount'].toString()) == amount &&
          tx['type'] == 'budget_expense',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyTransactions, json.encode(transactions));
    await refreshData();
  }

  String getStreakLevel(int count) {
    if (count == 0) return 'Base';
    if (count < 7) return 'Bronze';
    if (count < 30) return 'Silver';
    if (count < 90) return 'Gold';
    if (count < 180) return 'Platinum';
    return 'Diamond';
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    int streakCount = prefs.getInt(keyStreakCount) ?? 0;
    String lastSaveDateStr = prefs.getString(keyLastSaveDate) ?? "";

    if (lastSaveDateStr == todayStr) return;

    if (lastSaveDateStr.isNotEmpty) {
      final lastDate = DateFormat('yyyy-MM-dd').parse(lastSaveDateStr);
      final difference = now.difference(lastDate).inDays;

      if (difference == 1) {
        streakCount++;
      } else if (difference >= 3) {
        streakCount = 1;
      } else {
        streakCount = 1;
      }
    } else {
      streakCount = 1;
    }

    String streakLevel = getStreakLevel(streakCount);

    await prefs.setInt(keyStreakCount, streakCount);
    await prefs.setString(keyStreakLevel, streakLevel);
    await prefs.setString(keyLastSaveDate, todayStr);

    if (streakCount % 7 == 0) {
      sendNotification(
        '🔥 Streak Milestone!',
        'Amazing! You\'ve maintained a $streakCount day savings streak at $streakLevel level!',
      );
    }
  }

  void checkSavingsDeadlines() {
    for (var saving in savings) {
      if (saving.achieved) continue;

      final daysRemaining = saving.deadline.difference(DateTime.now()).inDays;

      if (daysRemaining < 0) {
        sendNotification(
          '⚠️ Savings Goal Overdue',
          'Your ${saving.name} goal is ${daysRemaining.abs()} days overdue. Current: ${CurrencyFormatter.format(saving.savedAmount)} / ${CurrencyFormatter.format(saving.targetAmount)}',
        );
      } else if (daysRemaining <= 3 && daysRemaining > 0) {
        sendNotification(
          '⏰ Savings Deadline Approaching',
          'Your ${saving.name} goal is due in $daysRemaining days. Current: ${CurrencyFormatter.format(saving.savedAmount)} / ${CurrencyFormatter.format(saving.targetAmount)}',
        );
      }
    }
  }

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

  void showAddIncomeDialog() {
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
              textCapitalization: TextCapitalization.words,
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
                totalIncome += amt;
                await prefs.setDouble(keyTotalIncome, totalIncome);
                await saveTransaction(titleCtrl.text, amt, "income");
                Navigator.pop(context);
                refreshData();
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void showSmartExpenseDialog() {
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
              handleSavingsExpense();
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_rounded, color: Colors.orange),
            title: const Text("Existing Budget"),
            onTap: () {
              Navigator.pop(context);
              handleBudgetExpense();
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
              showGeneralExpenseDialog();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void handleSavingsExpense() {
    final activeSavings = savings.where((s) => !s.achieved).toList();
    if (activeSavings.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SavingsPage(onTransactionAdded: onSavingsTransactionAdded),
        ),
      ).then((_) => refreshData());
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
                subtitle: Text(
                  "Balance: ${CurrencyFormatter.format(s.balance)}",
                ),
                onTap: () {
                  Navigator.pop(context);
                  showAmountDialog(
                    title: "Add funds to ${s.name}",
                    onConfirm: (amt) async {
                      s.savedAmount += amt;
                      if (s.savedAmount >= s.targetAmount && !s.achieved) {
                        s.achieved = true;
                        sendNotification(
                          '🎉 Goal Achieved!',
                          'Congratulations! You\'ve reached your ${s.name} savings goal of ${CurrencyFormatter.format(s.targetAmount)}!',
                        );
                      }
                      await syncSavings();
                      await saveTransaction(
                        "Saved for ${s.name}",
                        amt,
                        "savings_deduction",
                      );
                      await updateStreak();
                      refreshData();
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

  void handleBudgetExpense() {
    if (budgets.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BudgetPage(
            onTransactionAdded: onBudgetTransactionAdded,
            onExpenseDeleted: onBudgetExpenseDeleted,
          ),
        ),
      ).then((_) => refreshData());
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
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final b = budgets[index];
              return ListTile(
                title: Text(b.name),
                onTap: () {
                  Navigator.pop(context);
                  showBudgetDetailEntryDialog(b);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void showBudgetDetailEntryDialog(Budget budget) {
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
              textCapitalization: TextCapitalization.words,
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
                // Add expense to budget
                budget.expenses.add(Expense(name: titleCtrl.text, amount: amt));
                await syncBudgets();
                
                // DO NOT create a transaction - budget expenses are internal only
                // This ensures they don't affect the total balance or appear in transactions
                
                Navigator.pop(context);
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Budget expense added: ${titleCtrl.text}'),
                    backgroundColor: brandGreen,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
                
                refreshData();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void showGeneralExpenseDialog() {
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
              textCapitalization: TextCapitalization.words,
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
                await saveTransaction(titleCtrl.text, amt, "expense");
                Navigator.pop(context);
                refreshData();
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

  @override
  Widget build(BuildContext context) {
    String greetings() {
      final int hour = DateTime.now().hour;
      if (hour < 12) return 'Good Morning';
      if (hour < 17) return 'Good Afternoon';
      return 'Good Evening';
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: paddingAllMedium,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildBalanceCard(),
                    sizedBoxHeightLarge,
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    sizedBoxHeightSmall,
                    buildQuickActions(),
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
                    buildRecentTransactions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildBalanceCard() {
    double balance = totalIncome - totalExpenses;
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
            CurrencyFormatter.format(balance),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              statItem("Income", totalIncome, Icons.arrow_circle_down_rounded),
              statItem(
                "Expenses",
                totalExpenses,
                Icons.arrow_circle_up_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget statItem(String label, double amt, IconData icon) {
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
              CurrencyFormatter.format(amt),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildQuickActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionCard(
              icon: Icons.add,
              label: 'Add Income',
              onTap: showAddIncomeDialog,
            ),
            QuickActionCard(
              icon: Icons.remove,
              label: 'Expense',
              onTap: showSmartExpenseDialog,
            ),
            QuickActionCard(
              icon: Icons.receipt_long,
              label: 'All Trans.',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionsPage(),
                  ),
                );
                refreshData();
              },
            ),
          ],
        ),
        sizedBoxHeightSmall,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionCard(
              icon: Icons.savings,
              label: 'Savings',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavingsPage(
                      onTransactionAdded: onSavingsTransactionAdded,
                    ),
                  ),
                );
                refreshData();
              },
            ),
            QuickActionCard(
              icon: Icons.account_balance_wallet,
              label: 'Budgets',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BudgetPage(
                      onTransactionAdded: onBudgetTransactionAdded,
                      onExpenseDeleted: onBudgetExpenseDeleted,
                    ),
                  ),
                );
                refreshData();
              },
            ),
            QuickActionCard(
              icon: Icons.analytics,
              label: 'Analytics',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Analytics coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget buildRecentTransactions() {
    if (transactions.isEmpty) {
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

    final displayTransactions = transactions.length > 8
        ? transactions.sublist(0, 8)
        : transactions;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayTransactions.length,
      itemBuilder: (context, index) {
        return buildTransactionCard(displayTransactions[index], index);
      },
    );
  }

  Widget buildTransactionCard(Map<String, dynamic> tx, int index) {
    final theme = Theme.of(context);
    final isIncome = tx['type'] == 'income';
    final date = DateTime.parse(tx['date']);
    final time = DateFormat('hh:mm a').format(date);
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final isLocked =
        isTransactionLinkedToAchievedGoal(tx) ||
        isTransactionLinkedToCheckedBudget(tx);

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
      case 'budget_finalized':
        txIcon = Icons.check_circle;
        iconBgColor = brandGreen;
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
      direction: isLocked ? DismissDirection.none : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (isLocked) return false;
        await deleteTransaction(index);
        return false;
      },
      background: isLocked
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: errorColor,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 32,
              ),
            ),
      secondaryBackground: isLocked
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: errorColor,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 32,
              ),
            ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocked
                ? Colors.orange.shade300
                : Theme.of(context).colorScheme.onSurface.withAlpha(10),
            width: isLocked ? 2 : 1,
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
          leading: Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Icon(txIcon, color: iconBgColor, size: 30),
              ),
              if (isLocked)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock, color: Colors.white, size: 12),
                  ),
                ),
            ],
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
              if (isLocked) ...[
                const SizedBox(width: 12),
                Icon(Icons.lock, size: 12, color: Colors.orange.shade700),
              ],
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
                  getTypeLabel(tx['type']),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: iconBgColor),
                ),
              ),
              Text(
                "${isIncome ? '+' : '-'} ${CurrencyFormatter.format(amount)}",
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

  String getTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Income';
      case 'budget_expense':
        return 'Budget';
      case 'budget_finalized':
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

class Budget {
  String name;
  double total;
  List<Expense> expenses;
  String id;
  bool isChecked;
  DateTime? checkedDate;
  DateTime createdDate;

  Budget({
    String? id,
    required this.name,
    required this.total,
    List<Expense>? expenses,
    this.isChecked = false,
    this.checkedDate,
    DateTime? createdDate,
  }) : expenses = expenses ?? [],
       id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdDate = createdDate ?? DateTime.now();

  double get totalSpent => expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get amountLeft => total - totalSpent;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'total': total,
    'expenses': expenses.map((e) => e.toMap()).toList(),
    'isChecked': isChecked,
    'checkedDate': checkedDate?.toIso8601String(),
    'createdDate': createdDate.toIso8601String(),
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: map['name'],
    total: (map['total'] as num).toDouble(),
    expenses:
        (map['expenses'] as List?)?.map((e) => Expense.fromMap(e)).toList() ??
        [],
    isChecked: map['isChecked'] ?? map['checked'] ?? false,
    checkedDate: map['checkedDate'] != null
        ? DateTime.parse(map['checkedDate'])
        : null,
    createdDate: map['createdDate'] != null
        ? DateTime.parse(map['createdDate'])
        : DateTime.now(),
  );
}

class Expense {
  String name;
  double amount;
  String id;
  DateTime createdDate;

  Expense({
    String? id,
    required this.name,
    required this.amount,
    DateTime? createdDate,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdDate = createdDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'createdDate': createdDate.toIso8601String(),
  };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: map['name'],
    amount: (map['amount'] as num).toDouble(),
    createdDate: map['createdDate'] != null
        ? DateTime.parse(map['createdDate'])
        : DateTime.now(),
  );
}

class Saving {
  String name;
  double savedAmount;
  double targetAmount;
  DateTime deadline;
  bool achieved;
  String? iconCode;

  Saving({
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.deadline,
    this.achieved = false,
    this.iconCode,
  });

  double get balance => targetAmount - savedAmount;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'savedAmount': savedAmount,
      'targetAmount': targetAmount,
      'deadline': deadline.toIso8601String(),
      'achieved': achieved,
      'iconCode': iconCode,
    };
  }

  factory Saving.fromMap(Map<String, dynamic> map) {
    return Saving(
      name: map['name'] ?? 'Unnamed',
      savedAmount: map['savedAmount'] is String
          ? double.tryParse(map['savedAmount']) ?? 0.0
          : (map['savedAmount'] as num?)?.toDouble() ?? 0.0,
      targetAmount: map['targetAmount'] is String
          ? double.tryParse(map['targetAmount']) ?? 0.0
          : (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'])
          : DateTime.now().add(const Duration(days: 30)),
      achieved: map['achieved'] ?? false,
      iconCode: map['iconCode'],
    );
  }
}