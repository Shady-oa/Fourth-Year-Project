import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/analytics_page/analytics_helpers.dart';
import 'package:flutter/material.dart';

import 'analytics_card.dart';

class AnalyticsTopExpenses extends StatelessWidget {
  final List<Map<String, dynamic>> topExpenses;

  const AnalyticsTopExpenses({super.key, required this.topExpenses});

  @override
  Widget build(BuildContext context) {
    final top = topExpenses;
    if (top.isEmpty) return const SizedBox.shrink();

    final maxAmt = analyticsAmt(top.first) + analyticsFee(top.first);
    const medals = ['🥇', '🥈', '🥉', '4th', '5th'];

    return AnalyticsCard(
      title: 'Top 5 Expenses',
      icon: Icons.leaderboard_outlined,
      child: Column(
        children: top.asMap().entries.map((entry) {
          final idx = entry.key;
          final tx = entry.value;
          final amt = analyticsAmt(tx) + analyticsFee(tx);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(medals[idx], style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxAmt > 0 ? amt / maxAmt : 0,
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation(
                            idx == 0
                                ? Colors.amber.shade500
                                : accentColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  CurrencyFormatter.compact(amt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: errorColor,
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
