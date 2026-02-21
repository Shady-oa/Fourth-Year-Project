// ─────────────────────────────────────────────────────────────────────────────
// widgets/sheets/budget_options_sheet.dart
//
// Extracted from _BudgetPageState.showBudgetOptionsBottomSheet().
// ─────────────────────────────────────────────────────────────────────────────

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';
import 'package:flutter/material.dart';

void showBudgetOptionsSheet({
  required BuildContext context,
  required Budget budget,
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
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Budget name header
            Text(
              budget.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (budget.isChecked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Finalized — editing disabled',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Edit option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: budget.isChecked
                      ? Colors.grey.shade100
                      : accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: budget.isChecked ? Colors.grey : accentColor,
                  size: 20,
                ),
              ),
              title: Text(
                'Edit Budget',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: budget.isChecked ? Colors.grey : null,
                ),
              ),
              subtitle: budget.isChecked
                  ? const Text(
                      'Unfinalize budget to edit',
                      style: TextStyle(fontSize: 11),
                    )
                  : null,
              onTap: budget.isChecked
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      onEdit();
                    },
            ),
            // Delete option
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
                'Delete Budget',
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
