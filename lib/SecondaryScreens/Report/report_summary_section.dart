import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:flutter/material.dart';

// ─── Summary Section ──────────────────────────────────────────────────────────
class ReportSummarySection extends StatelessWidget {
  final double netBalance;
  final double filteredIncome;
  final double filteredExpenses;
  final double filteredSavings;
  final double expenseRatio;
  final double avgDailySpend;
  final double totalFeesPaid;
  final double savingsRate;
  final int transactionCount;
  final double priorExpenses;

  const ReportSummarySection({
    super.key,
    required this.netBalance,
    required this.filteredIncome,
    required this.filteredExpenses,
    required this.filteredSavings,
    required this.expenseRatio,
    required this.avgDailySpend,
    required this.totalFeesPaid,
    required this.savingsRate,
    required this.transactionCount,
    required this.priorExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changeAmt = filteredExpenses - priorExpenses;
    final changePct = priorExpenses > 0 ? (changeAmt / priorExpenses * 100) : 0.0;
    final isUp = changeAmt > 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withOpacity(0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.25),
                blurRadius: 16,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(netBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUp ? Icons.trending_up : Icons.trending_down,
                          color: isUp
                              ? Colors.red.shade200
                              : Colors.green.shade200,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${changePct.abs().toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: isUp
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _summaryStatCard(
                    'Income',
                    filteredIncome,
                    Icons.arrow_circle_down_rounded,
                    brandGreen,
                  ),
                  const SizedBox(width: 8),
                  _summaryStatCard(
                    'Expenses',
                    filteredExpenses,
                    Icons.arrow_circle_up_rounded,
                    errorColor,
                  ),
                  const SizedBox(width: 8),
                  _summaryStatCard(
                    'Savings',
                    filteredSavings,
                    Icons.savings,
                    Colors.lightBlue,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filteredIncome > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Expense ratio',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      '${expenseRatio.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (expenseRatio / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(
                      expenseRatio > 90
                          ? Colors.red.shade300
                          : expenseRatio > 70
                          ? Colors.orange.shade300
                          : Colors.green.shade300,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _miniStatCard(
              theme,
              'Avg/Day',
              CurrencyFormatter.compact(avgDailySpend),
              Icons.today,
              Colors.purple,
            ),
            const SizedBox(width: 8),
            _miniStatCard(
              theme,
              'Fees Paid',
              CurrencyFormatter.compact(totalFeesPaid),
              Icons.percent,
              Colors.orange,
            ),
            const SizedBox(width: 8),
            _miniStatCard(
              theme,
              'Transactions',
              '$transactionCount',
              Icons.receipt,
              accentColor,
            ),
            const SizedBox(width: 8),
            _miniStatCard(
              theme,
              'Savings Rate',
              '${savingsRate.toStringAsFixed(1)}%',
              Icons.savings_outlined,
              brandGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryStatCard(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.compact(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
