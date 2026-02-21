// ─────────────────────────────────────────────────────────────────────────────
// widgets/sheets/expense_options_sheet.dart
//
// Extracted from _BudgetDetailPageState.showExpenseOptionsBottomSheet().
// ─────────────────────────────────────────────────────────────────────────────

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';

import 'package:flutter/material.dart';

void showExpenseOptionsSheet({
  required BuildContext context,
  required Expense expense,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              expense.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              CurrencyFormatter.format(expense.amount),
              style: TextStyle(
                color: errorColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: accentColor,
                  size: 20,
                ),
              ),
              title: const Text(
                'Edit Expense',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: errorColor,
                  size: 20,
                ),
              ),
              title: const Text(
                'Delete Expense',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: errorColor,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
