import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Components/toast.dart';

/// Shows the "Add Expense" modal bottom sheet and calls [onContinue] with the
/// validated form values so the caller can run the confirmation flow.
void showAddExpenseSheet(
  BuildContext context, {
  required void Function({
    required String title,
    required double amount,
    required double transactionCost,
    required String reason,
  }) onContinue,
}) {
  final titleCtrl = TextEditingController();
  final amtCtrl = TextEditingController();
  final txCostCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();

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
              // Drag handle
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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_circle_up_rounded,
                      color: errorColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Expense',
                        style: GoogleFonts.urbanist(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Record a new expense',
                        style: GoogleFonts.urbanist(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What was it for?',
                  prefixIcon: Icon(Icons.receipt_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (Ksh)',
                  hintText: '0',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: txCostCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Transaction Fee (Ksh)',
                  hintText: 'e.g. M-Pesa fee (0 if none)',
                  prefixIcon: Icon(Icons.percent_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'e.g. Groceries for the week',
                  prefixIcon: Icon(Icons.notes_rounded),
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
                        backgroundColor: errorColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final amt = double.tryParse(amtCtrl.text) ?? 0;
                        final txCost =
                            double.tryParse(txCostCtrl.text) ?? 0;
                        final reason = reasonCtrl.text.trim();

                        if (amt <= 0 || titleCtrl.text.isEmpty) {
                          AppToast.warning(context,
                              'Please enter a name and valid amount');
                          return;
                        }
                        if (txCostCtrl.text.trim().isEmpty) {
                          AppToast.warning(context,
                              'Please enter transaction cost (0 if none)');
                          return;
                        }
                        if (reason.isEmpty) {
                          AppToast.warning(
                              context, 'Please enter a reason');
                          return;
                        }

                        Navigator.pop(ctx);
                        onContinue(
                          title: titleCtrl.text.trim(),
                          amount: amt,
                          transactionCost: txCost,
                          reason: reason,
                        );
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
