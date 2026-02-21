import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/SecondaryScreens/Report/report_helpers.dart';
import 'package:flutter/material.dart';

import 'report_card.dart';

// ─── Daily Spending Bars ──────────────────────────────────────────────────────
class ReportDailySpendingBars extends StatelessWidget {
  final List<DailyTotal> dailySpending;
  final double filteredExpenses;
  final double avgDailySpend;

  const ReportDailySpendingBars({
    super.key,
    required this.dailySpending,
    required this.filteredExpenses,
    required this.avgDailySpend,
  });

  @override
  Widget build(BuildContext context) {
    if (dailySpending.isEmpty) return const SizedBox.shrink();

    final maxAmt = dailySpending
        .map((d) => d.amount)
        .fold(0.0, (a, b) => a > b ? a : b);
    final showLabels = dailySpending.length <= 14;

    return ReportCard(
      title: 'Daily Spending',
      icon: Icons.bar_chart,
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailySpending.map((d) {
                final ratio = maxAmt > 0 ? d.amount / maxAmt : 0.0;
                final isMax = d.amount == maxAmt && maxAmt > 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Tooltip(
                      message:
                          '${d.day}\n${CurrencyFormatter.format(d.amount)}',
                      child: Container(
                        height: 110 * ratio + 4,
                        decoration: BoxDecoration(
                          color: isMax
                              ? errorColor
                              : accentColor.withOpacity(0.7),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            topRight: Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (showLabels) ...[
            const SizedBox(height: 4),
            Row(
              children: dailySpending
                  .map(
                    (d) => Expanded(
                      child: Text(
                        d.day.split('/').first,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total: ${CurrencyFormatter.format(filteredExpenses)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Text(
                'Avg: ${CurrencyFormatter.format(avgDailySpend)}/day',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
