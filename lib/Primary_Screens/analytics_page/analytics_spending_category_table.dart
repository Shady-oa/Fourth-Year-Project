import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:flutter/material.dart';

import 'analytics_card.dart';

class AnalyticsSpendingCategoryTable extends StatelessWidget {
  final Map<String, double> expensesByCategory;

  const AnalyticsSpendingCategoryTable({
    super.key,
    required this.expensesByCategory,
  });

  @override
  Widget build(BuildContext context) {
    final cats = expensesByCategory;
    if (cats.isEmpty) return const SizedBox.shrink();

    final total = cats.values.fold(0.0, (s, v) => s + v);
    final colors = [
      accentColor,
      brandGreen,
      Colors.orange,
      Colors.purple,
      errorColor,
      Colors.teal,
      Colors.pink,
    ];

    return AnalyticsCard(
      title: 'Spending Breakdown',
      icon: Icons.category_outlined,
      child: Column(
        children: cats.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final e = entry.value;
          final pct = total > 0 ? e.value / total : 0.0;
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
                        e.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.compact(e.value),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
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
