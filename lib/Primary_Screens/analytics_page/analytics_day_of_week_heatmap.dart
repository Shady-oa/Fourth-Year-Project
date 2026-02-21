import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

import 'analytics_card.dart';

class AnalyticsDayOfWeekHeatmap extends StatelessWidget {
  final List<Map<String, dynamic>> filteredTransactions;

  const AnalyticsDayOfWeekHeatmap({
    super.key,
    required this.filteredTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final counts = List.filled(7, 0);
    for (final tx in filteredTransactions) {
      counts[(DateTime.parse(tx['date']).weekday - 1) % 7]++;
    }
    final maxCount = counts.fold(0, (a, b) => a > b ? a : b);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return AnalyticsCard(
      title: 'Activity by Day',
      icon: Icons.calendar_view_week_outlined,
      child: Column(
        children: [
          Row(
            children: List.generate(7, (i) {
              final ratio = maxCount > 0 ? counts[i] / maxCount : 0.0;
              final isMax = counts[i] == maxCount && maxCount > 0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      Text(
                        '${counts[i]}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMax ? accentColor : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 60,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation(
                            isMax ? accentColor : accentColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        days[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: isMax ? accentColor : Colors.grey.shade600,
                          fontWeight: isMax
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (isMax)
                        const Text('🔥', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Total ${filteredTransactions.length} transactions in this period',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
