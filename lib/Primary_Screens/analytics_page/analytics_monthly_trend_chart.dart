import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'analytics_card.dart';

class AnalyticsMonthlyTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> last6MonthsData;

  const AnalyticsMonthlyTrendChart({
    super.key,
    required this.last6MonthsData,
  });

  @override
  Widget build(BuildContext context) {
    final data = last6MonthsData;
    final maxVal = data.fold(
      0.0,
      (m, d) => [
        m,
        d['income'] as double,
        d['expenses'] as double,
      ].reduce((a, b) => a > b ? a : b),
    );

    return AnalyticsCard(
      title: '6-Month Trend',
      icon: Icons.show_chart,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(brandGreen, 'Income'),
              const SizedBox(width: 16),
              _legendDot(errorColor, 'Expenses'),
              const SizedBox(width: 16),
              _legendDot(accentColor, 'Savings'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: maxVal == 0
                ? Center(
                    child: Text(
                      'No data',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxVal * 1.25,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.black87,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final labels = ['Income', 'Expenses', 'Savings'];
                            return BarTooltipItem(
                              '${labels[rodIndex]}\n${CurrencyFormatter.compact(rod.toY)}',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) => Text(
                              data[val.toInt()]['label'] as String,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (val, meta) => Text(
                              CurrencyFormatter.compact(val),
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
                        getDrawingHorizontalLine: (val) =>
                            FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.asMap().entries.map((entry) {
                        final i = entry.key;
                        final d = entry.value;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: d['income'] as double,
                              color: brandGreen,
                              width: 9,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: d['expenses'] as double,
                              color: errorColor,
                              width: 9,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: d['savings'] as double,
                              color: accentColor,
                              width: 9,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}
