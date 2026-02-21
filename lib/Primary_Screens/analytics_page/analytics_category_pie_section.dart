import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'analytics_card.dart';

class AnalyticsCategoryPieSection extends StatelessWidget {
  final Map<String, double> expensesByCategory;

  const AnalyticsCategoryPieSection({
    super.key,
    required this.expensesByCategory,
  });

  @override
  Widget build(BuildContext context) {
    final cats = expensesByCategory;
    if (cats.isEmpty) return const SizedBox.shrink();

    final colors = [
      accentColor,
      brandGreen,
      Colors.orange,
      Colors.purple,
      errorColor,
      Colors.teal,
      Colors.pink,
    ];
    final total = cats.values.fold(0.0, (s, v) => s + v);

    int ci = 0;
    final sections = cats.entries.map((e) {
      final color = colors[ci++ % colors.length];
      final pct = total > 0 ? (e.value / total) : 0.0;
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: pct > 0.06 ? '${(pct * 100).toStringAsFixed(0)}%' : '',
        radius: 58,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return AnalyticsCard(
      title: 'Expense Distribution',
      icon: Icons.pie_chart_outline,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cats.entries.toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  final color = colors[idx % colors.length];
                  final pct = total > 0 ? (e.value / total * 100) : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${pct.toStringAsFixed(0)}%  ${CurrencyFormatter.compact(e.value)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
