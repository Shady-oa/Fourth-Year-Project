import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Components/quick_actions.dart';
import 'package:final_project/Components/them_toggle.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/Transactions/transaction_widget1.dart';
import 'package:final_project/Primary_Screens/Transactions/transactions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

// Import the reusable calculations

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Use lists of Transaction objects directly to simplify
  // List<Transaction> transactions = [];
  final usersDB = FirebaseFirestore.instance.collection('users');
  final statsDB = FirebaseFirestore.instance.collection('statistics');
  final userUid = FirebaseAuth.instance.currentUser!.uid;
  final String year = DateTime.now().year.toString();
  String month = DateFormat('MM').format(DateTime.now());

  String? username;
  String? profileImage;
  StreamSubscription? userSubscription;

  void loadData() async {
    userSubscription = usersDB.doc(userUid).snapshots().listen((snapshots) {
      if (snapshots.exists) {
        final userData = snapshots.data() as Map<String, dynamic>;
        print('this is the userdata');
        print(userData);
        setState(() {
          username = userData['username'] ?? '';
          profileImage = userData['profileUrl'] ?? '';
        });
      }
    });
  }

  Stream<Map<String, dynamic>> getCombinedMonthData() {
    final expensesStream = statsDB
        .doc(userUid)
        .collection(year)
        .doc(month)
        .collection('transactions')
        .snapshots();

    final budgetsStream = statsDB
        .doc(userUid)
        .collection(year)
        .doc(month)
        .collection('budgets')
        .snapshots();

    final savingsStream = statsDB
        .doc(userUid)
        .collection(year)
        .doc(month)
        .collection('savings')
        .snapshots();

    return Rx.combineLatest3(expensesStream, budgetsStream, savingsStream, (
      QuerySnapshot e,
      QuerySnapshot b,
      QuerySnapshot s,
    ) {
      return {'expense': e.docs, 'savings': s.docs, 'budgets': b.docs};
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    userSubscription?.cancel();
    super.dispose();
  }

  /* void _recalculateTotals() {
    if (!mounted) return;
    setState(() {
      incomeList.clear();
      expenseList.clear();
      savingList.clear();
      for (var tx in transactions) {
        if (tx.type == "Income") incomeList.add(tx.amount);
        if (tx.type == "Expense") expenseList.add(tx.amount);
        if (tx.type == "Saving") savingList.add(tx.amount);
      }

      // Calculate total balance using the reusable utility
      double total = CalculationUtils.calculateTotalBalance(
        incomes: incomeList,
        expenses: expenseList,
        savings: savingList,
      );

      // Delay showing the toast by 8 seconds
      Future.delayed(const Duration(seconds: 8), () {
        if (!mounted) return;

        if (total < 0) {
          showCustomToast(
            context: context,
            message:
                "Warning! You are overspending by ${CalculationUtils.formatAmount(total.abs())}",
            backgroundColor: errorColor,
            icon: Icons.warning_amber_rounded,
          );
        } else if (total < 1000) {
          showCustomToast(
            context: context,
            message:
                "Caution! Your total balance is low: ${CalculationUtils.formatAmount(total)}",
            backgroundColor: warning,
            icon: Icons.warning_amber_rounded,
          );
        }
      });
    });
  }*/

  // Function to handle adding a new transaction
  /*void _addTransaction(String type, double value, String source) {
    setState(() {
      transactions.insert(
        0,
        Transaction(
          type: type,
          amount: value,
          source: source,
          dateTime: DateTime.now(),
        ),
      );
      _recalculateTotals();
    });
  }*/

  @override
  Widget build(BuildContext context) {
    // final recentTransactions = transactions.take(5).toList();

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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: Row(
          children: [
            SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundImage: (profileImage == null)
                  ? AssetImage("assets/image/icon 2.png")
                  : NetworkImage(profileImage!),
            ),
          ],
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greetings(), style: Theme.of(context).textTheme.headlineSmall),
            Text(username ?? '', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        actions: [
          Padding(
            padding: paddingAllTiny,
            child: Row(children: [const ThemeToggleIcon(), NotificationIcon()]),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder(
        stream: getCombinedMonthData(),
        builder: (context, snapshots) {
          if (!snapshots.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshots.data!;

          final expenses = data['expense'] as List<QueryDocumentSnapshot>;
          int totalIncome = 0;
          int totalExpenses = 0;
          int totalBalance = 0;
          List<Map<String, dynamic>> transactionsData = [];

          for (var tx in expenses) {
            transactionsData.add(tx.data() as Map<String, dynamic>);
            final map = tx.data() as Map<String, dynamic>;
            if (map['type'] == 'income') {
              String amount = map['amount'] ?? '0';
              totalIncome += int.parse(amount);
            } else if (map['type'] == 'expense') {
              String amount = map['amount'] ?? '0';
              totalExpenses += int.parse(amount);
            }
          }

          print('this is the list of the transactions✅✅✅✅');
          print(transactionsData);

          return SingleChildScrollView(
            child: Padding(
              padding: paddingAllMedium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance Section
                  _buildBalanceCard(
                    totalExpense: totalExpenses ?? 0,
                    totalIncome: totalIncome ?? 0,
                  ),
                  sizedBoxHeightLarge,
                  // Quick Actions Section
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  sizedBoxHeightSmall,
                  _buildQuickActions(),
                  sizedBoxHeightLarge,
                  // Recent Transactions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AllTransactionsPage(),
                            ),
                          );
                        },
                        child: Text(
                          'See all Transactions',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: accentColor,
                                decoration: TextDecoration.underline,
                                decorationColor: accentColor,
                                decorationThickness: 2,
                              ),
                        ),
                      ),
                    ],
                  ),
                  sizedBoxHeightSmall,

                  /* recentTransactions.isEmpty
                      ? buildEmptyTransactions(context)
                      : buildRecentTransactions(
                          context: context,
                          recentTransactions: recentTransactions,
                          transactions: transactions,
                          recalculateTotals: _recalculateTotals,
                          updateTransactions: (newList) {
                            setState(() {
                              transactions = newList;
                            });
                          },
                        ),*/
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: transactionsData.length,
                    itemBuilder: (contex, index) {
                      String name = transactionsData[index]['name'] ?? '';
                      String description =
                          transactionsData[index]['description'] ?? '';
                      String amount = transactionsData[index]['amount'] ?? '';
                      String type = transactionsData[index]['type'] ?? '';
                      Timestamp createdAt =
                          transactionsData[index]['createdAt'] ??
                          Timestamp.now();

                      return transactionCell(
                        name: name,
                        context: context,
                        description: description,
                        type: type,
                        amount: amount,
                        createdAt: createdAt,
                      );
                    },
                  ),
                ],
              ),
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface,
        borderRadius: radiusMedium,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.4),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          Text(
            ((totalIncome ?? 0) - (totalExpense ?? 0)).toString(),
            // CalculationUtils.totalBalance(
            //   incomes: incomeList,
            //   expenses: expenseList,
            // ),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          sizedBoxHeightLarge,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseColumn(
                context,
                'Income',
                (totalIncome ?? 0).toString(),
                Icons.arrow_circle_down_rounded,
              ),
              sizedBoxWidthLarge,
              _buildIncomeExpenseColumn(
                context,
                'Expenses',
                (totalExpense ?? 0).toString(),
                Icons.arrow_circle_up_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        QuickActionCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Add Income',
          onTap: () {
            /* showAddAmountDialog(context, 'Income', (value, source) {
              //_addTransaction('Income', value, source);
            });*/
          },
        ),
        QuickActionCard(
          icon: Icons.add_card_outlined,
          label: 'Add Expense',
          onTap: () {
            /*showAddAmountDialog(context, 'Expense', (value, source) {
              //_addTransaction('Expense', value, source);
            });*/
          },
        ),
        QuickActionCard(
          icon: Icons.savings_outlined,
          label: 'Add Saving',
          onTap: () {
            /*showAddAmountDialog(context, 'Saving', (value, source) {
              // _addTransaction('Saving', value, source);
            });*/
          },
        ),
        QuickActionCard(
          icon: Icons.analytics_outlined,
          label: 'Report',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseColumn(
    BuildContext context,
    String label,
    //List<double> list,
    String amount,
    IconData icon,
  ) {
    //final total = list.isEmpty ? 0.0 : CalculationUtils.calculateTotal(list);
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.surface.withOpacity(.6),
          size: 40,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
            Text(
              amount.toString(),
              //CalculationUtils.formatAmount(total),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
