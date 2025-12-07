import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Components/them_toggle.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/Transactions/alert_dialog.dart';
import 'package:final_project/Primary_Screens/transactions/transaction_widget.dart';
import 'package:final_project/Statistics/statistics.dart';
import 'package:flutter/material.dart';

class Transaction {
  final String type; // Income, Expense, Saving
  final double amount;
  final String source;
  final DateTime dateTime;

  Transaction({
    required this.type,
    required this.amount,
    required this.source,
    required this.dateTime,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<double> incomeList = [];
  List<double> expenseList = [];
  List<double> savingList = [];
  List<Transaction> transactions = [];

  @override
  void initState() {
    super.initState();
    _recalculateTotals();
  }

  void _recalculateTotals() {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final recentTransactions = transactions.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: Padding(
          padding: paddingAllTiny,
          child: const CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage("assets/image/icon 2.png"),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('Alex', style: Theme.of(context).textTheme.bodyLarge),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: paddingAllMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Section
              _buildBalanceCard(),
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
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              sizedBoxHeightSmall,
              recentTransactions.isEmpty
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
                    ),
            ],
          ),
        ),
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
            'Total Balance',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          Text(
            Statistics.totalBalance(
              incomes: incomeList,
              expenses: expenseList,
              savings: savingList,
            ),
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
                incomeList,
                Icons.arrow_circle_down_rounded,
              ),
              sizedBoxWidthLarge,
              _buildIncomeExpenseColumn(
                context,
                'Expenses',
                expenseList,
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
        _buildQuickActionCard(
          context,
          Icons.account_balance_wallet_outlined,
          'Add Income',
          () {
            showAddAmountDialog(context, 'Income', (value, source) {
              setState(() {
                transactions.insert(
                  0,
                  Transaction(
                    type: "Income",
                    amount: value,
                    source: source,
                    dateTime: DateTime.now(),
                  ),
                );
                _recalculateTotals();
              });
            });
          },
        ),
        _buildQuickActionCard(
          context,
          Icons.add_card_outlined,
          'Add Expense',
          () {
            showAddAmountDialog(context, 'Expense', (value, source) {
              setState(() {
                transactions.insert(
                  0,
                  Transaction(
                    type: "Expense",
                    amount: value,
                    source: source,
                    dateTime: DateTime.now(),
                  ),
                );
                _recalculateTotals();
              });
            });
          },
        ),
        _buildQuickActionCard(
          context,
          Icons.savings_outlined,
          'Add Saving',
          () {
            showAddAmountDialog(context, 'Saving', (value, source) {
              setState(() {
                transactions.insert(
                  0,
                  Transaction(
                    type: "Saving",
                    amount: value,
                    source: source,
                    dateTime: DateTime.now(),
                  ),
                );
                _recalculateTotals();
              });
            });
          },
        ),
        _buildQuickActionCard(
          context,
          Icons.analytics_outlined,
          'Report',
          () {},
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseColumn(
    BuildContext context,
    String label,
    List<double> list,
    IconData icon,
  ) {
    final total = list.isEmpty ? 0.0 : Statistics.calculateTotal(list);
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
              Statistics.formatAmount(total),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: paddingAllMedium,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: radiusMedium,
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          sizedBoxHeightSmall,
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  
}
