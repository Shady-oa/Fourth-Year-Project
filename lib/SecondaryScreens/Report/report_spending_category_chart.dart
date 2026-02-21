import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:flutter/material.dart';

import 'report_card.dart';
import 'report_empty_state.dart';

// ─── Spending Category Chart ──────────────────────────────────────────────────
class ReportSpendingCategoryChart extends StatelessWidget {
  final Map<String, double> spendingByCategory;

  const ReportSpendingCategoryChart({
    super.key,
    required this.spendingByCategory,
  });

  @override
  Widget build(BuildContext context) {
    if (spendingByCategory.isEmpty) {
      return const ReportEmptyState(
        title: 'No spending data',
        subtitle: 'Add expenses to see a breakdown',
      );
    }

    final total = spendingByCategory.values.fold(0.0, (s, v) => s + v);
    final colors = [
      accentColor,
      brandGreen,
      Colors.orange,
      Colors.purple,
      errorColor,
      Colors.teal,
    ];

    return ReportCard(
      title: 'Spending Breakdown',
      icon: Icons.donut_large,
      child: Column(
        children: spendingByCategory.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final cat = entry.value;
          final pct = total > 0 ? cat.value / total : 0.0;
          final color = colors[idx % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.compact(cat.value),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
