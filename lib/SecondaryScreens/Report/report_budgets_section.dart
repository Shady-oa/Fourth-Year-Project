import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';
import 'package:flutter/material.dart';

import 'report_empty_state.dart';

// ─── Budgets Section ──────────────────────────────────────────────────────────
class ReportBudgetsSection extends StatelessWidget {
  final List<Budget> budgets;

  const ReportBudgetsSection({super.key, required this.budgets});

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return const ReportEmptyState(
        title: 'No budgets',
        subtitle: 'Create budgets to track your spending',
      );
    }

    return Column(
      children: budgets.map((b) {
        final progress = b.total > 0
            ? (b.totalSpent / b.total).clamp(0.0, 1.0)
            : 0.0;
        final isOver = b.totalSpent > b.total;
        final color = isOver
            ? errorColor
            : progress > 0.8
            ? Colors.orange
            : brandGreen;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
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
                        Icon(
                          Icons.account_balance_wallet,
                          color: color,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.name,
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
                  if (b.isChecked)
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
                        'Finalized',
                        style: TextStyle(
                          fontSize: 10,
                          color: brandGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${CurrencyFormatter.compact(b.totalSpent)} spent',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% of ${CurrencyFormatter.compact(b.total)}',
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
              if (isOver) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: errorColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Over by ${CurrencyFormatter.format(b.totalSpent - b.total)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
