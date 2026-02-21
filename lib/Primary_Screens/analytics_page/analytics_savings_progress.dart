import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'analytics_card.dart';

class AnalyticsSavingsProgress extends StatelessWidget {
  final List<Saving> savings;

  const AnalyticsSavingsProgress({super.key, required this.savings});

  @override
  Widget build(BuildContext context) {
    if (savings.isEmpty) return const SizedBox.shrink();

    final achieved = savings.where((s) => s.achieved).length;

    return AnalyticsCard(
      title: 'Savings Goals',
      icon: Icons.savings_outlined,
      badge: '$achieved/${savings.length} achieved',
      child: Column(
        children: savings.map((s) {
          final color = s.achieved
              ? brandGreen
              : s.deadline.isBefore(DateTime.now())
              ? errorColor
              : accentColor;
          final daysLeft = s.deadline.difference(DateTime.now()).inDays;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (s.achieved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: brandGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: brandGreen),
                        ),
                        child: const Text(
                          'Achieved 🎉',
                          style: TextStyle(
                            fontSize: 10,
                            color: brandGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Text(
                        daysLeft < 0
                            ? '${daysLeft.abs()}d overdue'
                            : '$daysLeft days left',
                        style: TextStyle(
                          fontSize: 11,
                          color: daysLeft < 0
                              ? errorColor
                              : Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${CurrencyFormatter.compact(s.savedAmount)} saved',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${(s.progressPercent * 100).toStringAsFixed(0)}% of ${CurrencyFormatter.compact(s.targetAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: s.progressPercent,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Remaining: ${CurrencyFormatter.format(s.balance.clamp(0, double.infinity))}  ·  Due: ${DateFormat('dd MMM yyyy').format(s.deadline)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
