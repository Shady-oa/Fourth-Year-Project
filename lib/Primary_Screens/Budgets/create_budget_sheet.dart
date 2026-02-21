// ─────────────────────────────────────────────────────────────────────────────
// widgets/sheets/create_budget_sheet.dart
//
// Extracted from _BudgetPageState.showCreateBudgetDialog().
// ─────────────────────────────────────────────────────────────────────────────

import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_confirm_sheet.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showCreateBudgetSheet({
  required BuildContext context,
  required Future<void> Function(String name, double amount) onBudgetCreated,
}) {
  final nameCtrl = TextEditingController();
  final amountCtrl = TextEditingController();

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
                      Icons.account_balance_wallet_rounded,
                      color: accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Budget',
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Set a new spending limit',
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
                  labelText: 'Budget Name',
                  hintText: 'e.g. Groceries, Transport',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget Amount (Ksh)',
                  hintText: '0',
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
                            title: 'Confirm Budget',
                            icon: Icons.account_balance_wallet,
                            iconColor: accentColor,
                            rows: [
                              BudgetConfirmRow('Name', name),
                              BudgetConfirmRow(
                                'Budget Amount',
                                CurrencyFormatter.format(amount),
                              ),
                            ],
                            confirmLabel: 'Create Budget',
                            confirmColor: accentColor,
                            onConfirm: () => onBudgetCreated(name, amount),
                          );
                        } else {
                          AppToast.warning(
                            context,
                            'Please enter a valid name and amount',
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
