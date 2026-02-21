import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Components/toast.dart';

/// Shows the "Add Income" modal bottom sheet and calls [onContinue] with the
/// validated form values so the caller can run the confirmation flow.
void showAddIncomeSheet(
  BuildContext context, {
  required void Function({
    required String title,
    required double amount,
    required String reason,
  }) onContinue,
}) {
  final amountCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
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
                      color: brandGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_circle_down_rounded,
                      color: brandGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Income',
                        style: GoogleFonts.urbanist(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Record a new income source',
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
                  labelText: 'Income Source',
                  hintText: 'e.g. Salary, Freelance',
                  prefixIcon: Icon(Icons.work_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (Ksh)',
                  hintText: '0',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'e.g. Monthly salary, freelance payment',
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
                        backgroundColor: brandGreen,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final amt = double.tryParse(amountCtrl.text) ?? 0;
                        final reason = reasonCtrl.text.trim();
                        if (amt > 0 &&
                            titleCtrl.text.isNotEmpty &&
                            reason.isNotEmpty) {
                          Navigator.pop(ctx);
                          onContinue(
                            title: titleCtrl.text.trim(),
                            amount: amt,
                            reason: reason,
                          );
                        } else {
                          AppToast.warning(
                            context,
                            'Please fill all fields (amount, source & reason)',
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
