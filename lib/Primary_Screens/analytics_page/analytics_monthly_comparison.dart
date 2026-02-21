import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:flutter/material.dart';

import 'analytics_card.dart';

class AnalyticsMonthlyComparison extends StatelessWidget {
  final Map<String, dynamic> monthlyComparison;

  const AnalyticsMonthlyComparison({
    super.key,
    required this.monthlyComparison,
  });

  @override
  Widget build(BuildContext context) {
    final cmp = monthlyComparison;
    final change = cmp['change'] as double;
    final isUp = change > 0;

    return AnalyticsCard(
      title: 'Month vs Last Month',
      icon: Icons.compare_arrows_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _comparisonStat(
                  'This Month',
                  cmp['thisMonthExp'],
                  'Expenses',
                  errorColor,
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey.shade100),
              Expanded(
                child: _comparisonStat(
                  'Last Month',
                  cmp['lastMonthExp'],
                  'Expenses',
                  Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _comparisonStat(
                  'This Month',
                  cmp['thisMonthInc'],
                  'Income',
                  brandGreen,
                ),
              ),
              Container(width: 1, height: 60, color: Colors.grey.shade100),
              Expanded(
                child: _comparisonStat(
                  'Last Month',
                  cmp['lastMonthInc'],
                  'Income',
                  Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isUp ? errorColor : brandGreen).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isUp ? Icons.trending_up : Icons.trending_down,
                  color: isUp ? errorColor : brandGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${change.abs().toStringAsFixed(1)}% ${isUp ? 'higher' : 'lower'} spending vs last month',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUp ? errorColor : brandGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonStat(
    String period,
    double amount,
    String label,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.compact(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
