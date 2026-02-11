import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Components/quick_actions.dart';
import 'package:final_project/Components/them_toggle.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/Budgets/budget.dart';
import 'package:final_project/Primary_Screens/Savings/savings.dart';
import 'package:final_project/Primary_Screens/Transactions/transaction_widget1.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final usersDB = FirebaseFirestore.instance.collection('users');
  final statsDB = FirebaseFirestore.instance.collection('statistics');
  final userUid = FirebaseAuth.instance.currentUser!.uid;
  final String year = DateTime.now().year.toString();
  String month = DateFormat('MM').format(DateTime.now());

  String? username;
  String? profileImage;
  StreamSubscription? userSubscription;

  @override
  void initState() {
    super.initState();
    loadData();
    checkAndInitYearlyData();
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    super.dispose();
  }

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

  Future<void> checkAndInitYearlyData() async {
    final yearDocRef = statsDB.doc(userUid).collection(year);
    final janDoc = await yearDocRef.doc('01').get();

    if (!janDoc.exists) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      List<String> months = List.generate(
        12,
        (i) => (i + 1).toString().padLeft(2, '0'),
      );
      for (String m in months) {
        DocumentReference monthRef = yearDocRef.doc(m);
        batch.set(monthRef, {
          'initializedAt': FieldValue.serverTimestamp(),
          'monthName': DateFormat('MMMM').format(DateTime(2026, int.parse(m))),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  Stream<Map<String, dynamic>> getCombinedMonthData() {
    final baseRef = statsDB.doc(userUid).collection(year).doc(month);
    final expensesStream = baseRef
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots();
    final budgetsStream = baseRef.collection('budgets').snapshots();
    final savingsStream = baseRef.collection('savings').snapshots();

    return Rx.combineLatest3(expensesStream, budgetsStream, savingsStream, (
      QuerySnapshot e,
      QuerySnapshot b,
      QuerySnapshot s,
    ) {
      return {'expense': e.docs, 'savings': s.docs, 'budgets': b.docs};
    });
  }

  // --- LOGIC: SMART EXPENSE ROUTING ---

  void _showSmartExpenseDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "What is this expense for?",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.orange),
                title: const Text("Existing Budget"),
                onTap: () {
                  Navigator.pop(context);
                  _showSelectionDialog('budgets', 'bName');
                },
              ),
              ListTile(
                leading: const Icon(Icons.savings, color: Colors.green),
                title: const Text("Savings Goal"),
                onTap: () {
                  Navigator.pop(context);
                  _showSelectionDialog('savings', 'gName');
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
            ],
          ),
        );
      },
    );
  }

  void _showSelectionDialog(String collection, String fieldName) async {
    final snapshots = await statsDB
        .doc(userUid)
        .collection(year)
        .doc(month)
        .collection(collection)
        .get();

    if (snapshots.docs.isEmpty) {
      _showNoItemsAlert(collection);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select ${collection.substring(0, collection.length - 1)}"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: snapshots.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshots.docs[index];
              var data = doc.data();

              // CRITICAL: Check if saving is already achieved
              bool isAchieved = false;
              if (collection == 'savings') {
                double saved =
                    double.tryParse(data['savedAmount'].toString()) ?? 0.0;
                double target =
                    double.tryParse(data['tAmount'].toString()) ?? 0.0;
                isAchieved = saved >= target;
              }

              return ListTile(
                title: Text(data[fieldName]),
                subtitle: isAchieved
                    ? const Text(
                        "Goal Achieved ✅",
                        style: TextStyle(color: Colors.green),
                      )
                    : null,
                enabled: !isAchieved, // Disable if achieved
                onTap: () {
                  Navigator.pop(context);
                  _showAmountEntryDialog(
                    type: collection == 'savings' ? 'saving' : 'expense',
                    targetId: doc.id,
                    targetName: data[fieldName],
                    collection: collection,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAmountEntryDialog({
    required String type,
    required String targetId,
    required String targetName,
    required String collection,
  }) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add to $targetName"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter Amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _processTransaction(
                amount: amountController.text,
                type: type,
                name: targetName,
                targetId: targetId,
                collection: collection,
              );
              Navigator.pop(context);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showGeneralExpenseDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Other Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "What for?"),
            ),
            TextField(
              controller: amountController,
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
            onPressed: () {
              _processTransaction(
                amount: amountController.text,
                type: 'expense',
                name: nameController.text,
              );
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _processTransaction({
    required String amount,
    required String type,
    required String name,
    String? targetId,
    String? collection,
  }) async {
    if (amount.isEmpty) return;
    final baseRef = statsDB.doc(userUid).collection(year).doc(month);

    // 1. Add to Transactions (This is what affects the Balance Card stats)
    await baseRef.collection('transactions').add({
      'name': name,
      'amount': amount,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Update Progress on the specific Budget/Saving
    if (targetId != null && collection != null) {
      final docRef = baseRef.collection(collection).doc(targetId);
      if (collection == 'budgets') {
        docRef.update({
          'usedAmount': FieldValue.increment(double.parse(amount)),
        });
      } else if (collection == 'savings') {
        docRef.update({
          'savedAmount': FieldValue.increment(double.parse(amount)),
        });
      }
    }
  }

  void _showNoItemsAlert(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("No $type found"),
        content: Text("Please create a $type first."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            backgroundImage: (profileImage == null)
                ? const AssetImage("assets/image/icon.png")
                : NetworkImage(profileImage!) as ImageProvider,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Penny Wise",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              username ?? 'User',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        actions: [const ThemeToggleIcon(), NotificationIcon()],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder(
        stream: getCombinedMonthData(),
        builder: (context, snapshots) {
          if (!snapshots.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshots.data!;
          final expenses = data['expense'] as List<QueryDocumentSnapshot>;

          int totalIncome = 0;
          int totalExpenses = 0;

          // CRITICAL: Dashboard only reflects items in the 'transactions' collection
          for (var tx in expenses) {
            final map = tx.data() as Map<String, dynamic>;
            int amt = int.tryParse(map['amount'].toString()) ?? 0;
            if (map['type'] == 'income')
              totalIncome += amt;
            else
              totalExpenses += amt;
          }

          return Padding(
            padding: paddingAllMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(
                  totalIncome: totalIncome,
                  totalExpense: totalExpenses,
                ),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: expenses.length > 5 ? 5 : expenses.length,
                    itemBuilder: (context, index) {
                      final tx = expenses[index].data() as Map<String, dynamic>;
                      return transactionCell(
                        name: tx['name'],
                        context: context,
                        description: tx['type'],
                        type: tx['type'],
                        amount: tx['amount'].toString(),
                        createdAt: tx['createdAt'] ?? Timestamp.now(),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard({
    required int totalIncome,
    required int totalExpense,
  }) {
    return Container(
      width: double.infinity,
      padding: paddingAllMedium,
      decoration: BoxDecoration(borderRadius: radiusLarge, color: brandGreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Balance', style: TextStyle(color: Colors.white70)),
          Text(
            "Ksh ${totalIncome - totalExpense}",
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
              _statItem("Income", totalIncome.toString(), Icons.arrow_downward),
              _statItem(
                "Expenses",
                totalExpense.toString(),
                Icons.arrow_upward,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String amt, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              "Ksh $amt",
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
          onTap: () => _showIncomeDialog(),
        ),
        QuickActionCard(
          icon: Icons.remove,
          label: 'Expense',
          onTap: () => _showSmartExpenseDialog(),
        ),
        QuickActionCard(
          icon: Icons.account_balance,
          label: 'Budgets',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BudgetScreen()),
          ),
        ),
        QuickActionCard(
          icon: Icons.savings,
          label: 'Savings',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SavingsScreen()),
          ),
        ),
      ],
    );
  }

  void _showIncomeDialog() {
    final amtController = TextEditingController();
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Income"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "Source"),
            ),
            TextField(
              controller: amtController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Amount"),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _processTransaction(
                amount: amtController.text,
                type: 'income',
                name: nameController.text,
              );
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
