import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Components/quick_actions.dart';
import 'package:final_project/Components/them_toggle.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/Transactions/alert_dialog.dart';
import 'package:final_project/Primary_Screens/Transactions/transactions.dart';
import 'package:final_project/Primary_Screens/transactions/transaction_widget.dart';
import 'package:final_project/Statistics/statistics.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Use lists of Transaction objects directly to simplify
  List<Transaction> transactions = [];
  List<double> incomeList = [];
  List<double> expenseList = [];
  List<double> savingList = [];

  @override
  void initState() {
    super.initState();
    // Initialize with some dummy data for demonstration

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
  }

  // Function to handle adding a new transaction
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            CalculationUtils.totalBalance(
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
        QuickActionCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Add Income',
          onTap: () {
            showAddAmountDialog(context, 'Income', (value, source) {
              _addTransaction('Income', value, source);
            });
          },
        ),
        QuickActionCard(
          icon: Icons.add_card_outlined,
          label: 'Add Expense',
          onTap: () {
            showAddAmountDialog(context, 'Expense', (value, source) {
              _addTransaction('Expense', value, source);
            });
          },
        ),
        QuickActionCard(
          icon: Icons.savings_outlined,
          label: 'Add Saving',
          onTap: () {
            showAddAmountDialog(context, 'Saving', (value, source) {
              _addTransaction('Saving', value, source);
            });
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
    List<double> list,
    IconData icon,
  ) {
    final total = list.isEmpty ? 0.0 : CalculationUtils.calculateTotal(list);
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
              CalculationUtils.formatAmount(total),
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
