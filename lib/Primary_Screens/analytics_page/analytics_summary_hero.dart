import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';

class AnalyticsSummaryHero extends StatelessWidget {
  final String selectedFilter;
  final double netBalance;
  final double filteredIncome;
  final double filteredExpenses;
  final double filteredSavings;
  final double expenseRatio;
  final double savingsRate;
  final double avgDailySpend;
  final double totalFeesPaid;
  final int transactionCount;
  final int goalsAchieved;
  final int totalGoals;

  const AnalyticsSummaryHero({
    super.key,
    required this.selectedFilter,
    required this.netBalance,
    required this.filteredIncome,
    required this.filteredExpenses,
    required this.filteredSavings,
    required this.expenseRatio,
    required this.savingsRate,
    required this.avgDailySpend,
    required this.totalFeesPaid,
    required this.transactionCount,
    required this.goalsAchieved,
    required this.totalGoals,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = netBalance >= 0;

    return Column(
      children: [
        // Big gradient net balance card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPositive
                  ? [accentColor, accentColor.withOpacity(0.7)]
                  : [errorColor, errorColor.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isPositive ? accentColor : errorColor).withOpacity(0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Net Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      selectedFilter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                CurrencyFormatter.format(netBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 20),
              IntrinsicHeight(
                child: Row(
                  children: [
                    _heroStat(
                      'Income',
                      filteredIncome,
                      Icons.arrow_circle_down_rounded,
                      Colors.greenAccent.shade200,
                    ),
                    VerticalDivider(
                      color: Colors.white.withOpacity(0.2),
                      thickness: 1,
                      width: 20,
                    ),
                    _heroStat(
                      'Expenses',
                      filteredExpenses,
                      Icons.arrow_circle_up_rounded,
                      Colors.red.shade200,
                    ),
                    VerticalDivider(
                      color: Colors.white.withOpacity(0.2),
                      thickness: 1,
                      width: 20,
                    ),
                    _heroStat(
                      'Savings',
                      filteredSavings,
                      Icons.savings,
                      Colors.lightBlue.shade200,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ratioBar(
                'Expense ratio',
                expenseRatio / 100,
                expenseRatio > 90
                    ? Colors.red.shade300
                    : expenseRatio > 70
                    ? Colors.orange.shade300
                    : Colors.green.shade300,
                '${expenseRatio.toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 6),
              _ratioBar(
                'Savings rate',
                savingsRate / 100,
                savingsRate >= 20
                    ? Colors.greenAccent.shade200
                    : Colors.orange.shade300,
                '${savingsRate.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ),
        sizedBoxHeightMedium,
        // KPI row
        Row(
          children: [
            _kpiCard(
              context,
              'Avg/Day',
              CurrencyFormatter.compact(avgDailySpend),
              Icons.today,
              Colors.purple,
            ),
            const SizedBox(width: 8),
            _kpiCard(
              context,
              'Fees',
              CurrencyFormatter.compact(totalFeesPaid),
              Icons.receipt_outlined,
              Colors.orange,
            ),
            const SizedBox(width: 8),
            _kpiCard(
              context,
              'Transactions',
              '$transactionCount',
              Icons.receipt_long,
              accentColor,
            ),
            const SizedBox(width: 8),
            _kpiCard(
              context,
              'Goals Done',
              '$goalsAchieved/$totalGoals',
              Icons.flag_rounded,
              brandGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroStat(String label, double amount, IconData icon, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            CurrencyFormatter.compact(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratioBar(String label, double value, Color color, String badge) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
            Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: Colors.white.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
