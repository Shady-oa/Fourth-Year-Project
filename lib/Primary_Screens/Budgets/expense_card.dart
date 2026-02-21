// ─────────────────────────────────────────────────────────────────────────────
// widgets/expense_card.dart
//
// Extracted from _BudgetDetailPageState.buildExpenseCard().
// ─────────────────────────────────────────────────────────────────────────────

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final bool isFinalized;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.isFinalized,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 24-hour format
    final timeStr = DateFormat('HH:mm').format(expense.createdDate);
    final dateStr = DateFormat('dd MMM yyyy').format(expense.createdDate);

    return GestureDetector(
      onTap: isFinalized ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFinalized
                ? Colors.orange.shade200
                : theme.colorScheme.onSurface.withAlpha(15),
            width: isFinalized ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // No icon — clean minimal list
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateStr · $timeStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(expense.amount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: errorColor,
                  ),
                ),
                if (!isFinalized)
                  Text(
                    'tap to edit',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
