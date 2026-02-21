import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/SecondaryScreens/Report/report_helpers.dart';
import 'package:flutter/material.dart';

import 'report_card.dart';

// ─── Top Expenses ─────────────────────────────────────────────────────────────
class ReportTopExpenses extends StatelessWidget {
  final List<Map<String, dynamic>> topExpenses;

  const ReportTopExpenses({super.key, required this.topExpenses});

  @override
  Widget build(BuildContext context) {
    if (topExpenses.isEmpty) return const SizedBox.shrink();
    final maxAmt = reportAmt(topExpenses.first) + reportFee(topExpenses.first);

    return ReportCard(
      title: 'Top 5 Expenses',
      icon: Icons.leaderboard,
      child: Column(
        children: topExpenses.asMap().entries.map((entry) {
          final idx = entry.key;
          final tx = entry.value;
          final total = reportAmt(tx) + reportFee(tx);
          final ratio = maxAmt > 0 ? total / maxAmt : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: idx == 0
                            ? Colors.amber.shade400
                            : idx == 1
                            ? Colors.grey.shade400
                            : accentColor.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tx['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.compact(total),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: errorColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(
                      idx == 0
                          ? Colors.amber.shade400
                          : accentColor.withOpacity(0.7),
                    ),
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
