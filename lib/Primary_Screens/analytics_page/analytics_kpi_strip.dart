import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:flutter/material.dart';

class AnalyticsKpiStrip extends StatelessWidget {
  final double netBalance;
  final double savingsRate;
  final double expenseRatio;
  final double avgDailySpend;
  final double totalFeesPaid;
  final double projectedMonthEndSpend;

  const AnalyticsKpiStrip({
    super.key,
    required this.netBalance,
    required this.savingsRate,
    required this.expenseRatio,
    required this.avgDailySpend,
    required this.totalFeesPaid,
    required this.projectedMonthEndSpend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.08),
            accentColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stripStat(
                'Net Balance',
                CurrencyFormatter.compact(netBalance),
                netBalance >= 0 ? brandGreen : errorColor,
              ),
              _vDivider(),
              _stripStat(
                'Savings Rate',
                '${savingsRate.toStringAsFixed(1)}%',
                savingsRate >= 20 ? brandGreen : Colors.orange,
              ),
              _vDivider(),
              _stripStat(
                'Expense Ratio',
                '${expenseRatio.toStringAsFixed(1)}%',
                expenseRatio > 90
                    ? errorColor
                    : expenseRatio > 70
                    ? Colors.orange
                    : brandGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stripStat(
                'Avg Daily',
                CurrencyFormatter.compact(avgDailySpend),
                accentColor,
              ),
              _vDivider(),
              _stripStat(
                'Fees Paid',
                CurrencyFormatter.compact(totalFeesPaid),
                Colors.orange,
              ),
              _vDivider(),
              _stripStat(
                'Projected',
                CurrencyFormatter.compact(projectedMonthEndSpend),
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stripStat(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
    ],
  );

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: Colors.grey.shade200);
}
