// ─────────────────────────────────────────────────────────────────────────────
// widgets/sheets/edit_expense_sheet.dart
//
// Extracted from _BudgetDetailPageState._showEditExpenseDialog().
// ─────────────────────────────────────────────────────────────────────────────

import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_confirm_sheet.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

void showEditExpenseSheet({
  required BuildContext context,
  required Expense expense,
  required Future<void> Function(String name, double amount) onSaved,
}) {
  final nameCtrl = TextEditingController(text: expense.name);
  final amountCtrl = TextEditingController(
    text: expense.amount.toStringAsFixed(0),
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Expense',
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Update expense details',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Expense Title',
                  prefixIcon: Icon(Icons.receipt_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (Ksh)',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final amount = double.tryParse(amountCtrl.text) ?? 0;
                        if (name.isNotEmpty && amount > 0) {
                          Navigator.pop(ctx);
                          showBudgetConfirmSheet(
                            context: context,
                            title: 'Confirm Edit',
                            icon: Icons.edit_outlined,
                            iconColor: accentColor,
                            rows: [
                              BudgetConfirmRow('Expense', name),
                              BudgetConfirmRow(
                                'New Amount',
                                CurrencyFormatter.format(amount),
                                highlight: true,
                              ),
                            ],
                            confirmLabel: 'Save Changes',
                            confirmColor: accentColor,
                            onConfirm: () => onSaved(name, amount),
                          );
                        } else {
                          AppToast.warning(
                            context,
                            'Please enter valid name and amount',
                          );
                        }
                      },
                      child: const Text('Continue ›'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
