import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'report_empty_state.dart';

// ─── Savings Section ──────────────────────────────────────────────────────────
class ReportSavingsSection extends StatelessWidget {
  final List<Saving> savings;

  const ReportSavingsSection({super.key, required this.savings});

  @override
  Widget build(BuildContext context) {
    if (savings.isEmpty) {
      return const ReportEmptyState(
        title: 'No savings goals',
        subtitle: 'Create goals to start saving',
      );
    }

    return Column(
      children: savings.map((s) {
        final progress = s.progressPercent;
        final daysLeft = s.deadline.difference(DateTime.now()).inDays;
        final isOverdue = daysLeft < 0;
        final isAchieved = s.achieved;
        final color = isAchieved
            ? brandGreen
            : isOverdue
            ? errorColor
            : accentColor;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOverdue
                  ? errorColor.withOpacity(0.3)
                  : Colors.grey.shade100,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.savings, color: color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAchieved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: brandGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: brandGreen),
                      ),
                      child: const Text(
                        'Achieved! 🎉',
                        style: TextStyle(
                          fontSize: 10,
                          color: brandGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      isOverdue
                          ? '${daysLeft.abs()}d overdue'
                          : '$daysLeft days left',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? errorColor : Colors.grey.shade500,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${CurrencyFormatter.compact(s.savedAmount)} saved',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% of ${CurrencyFormatter.compact(s.targetAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining: ${CurrencyFormatter.format(s.balance.clamp(0, double.infinity))}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    'Due: ${DateFormat('dd MMM yyyy').format(s.deadline)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
