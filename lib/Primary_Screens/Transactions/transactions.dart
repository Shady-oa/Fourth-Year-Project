import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/Transactions/alert_dialog.dart';
import 'package:final_project/Primary_Screens/Transactions/transaction_widget1.dart';
import 'package:final_project/Primary_Screens/transactions/transaction_widget.dart';
import 'package:final_project/Statistics/statistics.dart';
import 'package:flutter/material.dart';

class AllTransactionsPage extends StatefulWidget {
  List<QueryDocumentSnapshot> expenses;
  int totalTransaction;

  AllTransactionsPage({
    super.key,
    required this.expenses,
    required this.totalTransaction,
  });

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  //List<Transaction> transactions = [];
  //List<double> incomeList = [];
  // List<double> expenseList = [];
  //List<double> savingList = [];
  List<Map<String, dynamic>> transactions = [];
  bool showQuickActions = false;

  @override
  void initState() {
    super.initState();
    addData(widget.expenses);
    // _recalculateTotals();
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void addData(List<QueryDocumentSnapshot> exp) {
    for (var tx in exp) {
      transactions.add(tx.data() as Map<String, dynamic>);
    }
  }
  /*void _recalculateTotals() {
    if (!mounted) return;
    setState(() {
      incomeList.clear();
      expenseList.clear();
      //savingList.clear();
      for (var tx in transactions) {
        if (tx.type == "Income") incomeList.add(tx.amount);
        if (tx.type == "Expense") expenseList.add(tx.amount);
        //if (tx.type == "Saving") savingList.add(tx.amount);
      }

      double total = CalculationUtils.calculateTotalBalance(
        incomes: incomeList,
        expenses: expenseList,
        //savings: savingList,
      );

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
  }

  void _addTransaction(String type, double value, String source) {
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
    //final allTransactions = transactions;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const CustomHeader(headerName: "Transactions"),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Padding(
            padding: paddingAllMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(),
                sizedBoxHeightLarge,
                Text(
                  'Transaction History (${transactions.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                sizedBoxHeightSmall,
                transactions.isEmpty
                    ? buildEmptyTransactions(context)
                    : Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          //shrinkWrap: true,
                          itemCount: transactions.length,
                          itemBuilder: (contex, index) {
                            String name = transactions[index]['name'] ?? '';
                            String description =
                                transactions[index]['description'] ?? '';
                            String amount = transactions[index]['amount'] ?? '';
                            String type = transactions[index]['type'] ?? '';
                            Timestamp createdAt =
                                transactions[index]['createdAt'] ??
                                Timestamp.now();

                            return transactionCell(
                              name: capitalize(name),
                              context: context,
                              description: capitalize(description),
                              type: type,
                              amount: amount,
                              createdAt: createdAt,
                            );
                          },
                        ),
                      ),
                // Space for FAB and menu
              ],
            ),
          ),

          // Quick Actions Column overlay
          if (showQuickActions)
            Positioned(
              bottom: 0, // 10px above FAB
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildCircularQuickAction(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Income',
                    type: 'Income',
                  ),
                  const SizedBox(height: 16),
                  _buildCircularQuickAction(
                    icon: Icons.add_card_outlined,
                    label: 'Expense',
                    type: 'Expense',
                  ),
                  const SizedBox(height: 16),
                  _buildCircularQuickAction(
                    icon: Icons.savings_outlined,
                    label: 'Saving',
                    type: 'Saving',
                  ),
                  SizedBox(height: 120),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => showQuickActions = !showQuickActions),
        shape: const CircleBorder(),
        child: showQuickActions
            ? Text(
                "Close",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: textLightMode),
              )
            : Text(
                "Add",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: textLightMode),
              ),
      ),
    );
  }

  Widget _buildCircularQuickAction({
    required IconData icon,
    required String label,
    required String type,
  }) {
    return GestureDetector(
      onTap: () {
        /*showAddAmountDialog(context, type, (value, source) {
          _addTransaction(type, value, source);
          setState(() => showQuickActions = false);
        });*/
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
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
            'Total Transactions',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          Text(
            widget.totalTransaction.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}
