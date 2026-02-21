import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/home/confirm_row.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:final_project/Constants/colors.dart';



/// Shows a full transaction summary for the user to review before saving.
/// [onConfirm] is invoked only when the user taps "Confirm & Save".
void showTransactionConfirmation(
  BuildContext context, {
  required String type,
  required String title,
  required double amount,
  required double transactionCost,
  required String reason,
  required double currentBalance,
  required Future<void> Function() onConfirm,
}) {
  final isIncome = type == 'income';
  final total = amount + transactionCost;
  final newBalance = isIncome ? currentBalance + amount : currentBalance - total;
  final balanceChange = isIncome ? amount : -total;
  final balancePositive = balanceChange >= 0;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      bool isSaving = false;
      return StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isIncome ? brandGreen : errorColor)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isIncome
                          ? Icons.arrow_circle_down_rounded
                          : Icons.arrow_circle_up_rounded,
                      color: isIncome ? brandGreen : errorColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Transaction',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isIncome ? 'Income' : 'Expense',
                        style: TextStyle(
                          color: isIncome ? brandGreen : errorColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              // Detail rows
              ConfirmRow('Description', title),
              ConfirmRow('Amount', CurrencyFormatter.formatDecimal(amount)),
              if (!isIncome && transactionCost > 0)
                ConfirmRow('Transaction Fee',
                    CurrencyFormatter.formatDecimal(transactionCost)),
              if (!isIncome && transactionCost > 0)
                ConfirmRow(
                    'Total Deducted', CurrencyFormatter.formatDecimal(total),
                    highlight: true),
              ConfirmRow('Reason', reason),
              ConfirmRow('Date',
                  DateFormat('d MMM yyyy, h:mm a').format(DateTime.now())),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Balance impact
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (balancePositive ? brandGreen : errorColor)
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (balancePositive ? brandGreen : errorColor)
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Balance After Transaction',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatDecimal(newBalance),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: newBalance < 0 ? errorColor : brandGreen,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (balancePositive ? brandGreen : errorColor)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${balancePositive ? '+' : ''} ${CurrencyFormatter.formatDecimal(balanceChange)}',
                        style: TextStyle(
                          color:
                              balancePositive ? brandGreen : errorColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Go Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isIncome ? brandGreen : errorColor,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheetState(() => isSaving = true);
                              await onConfirm();
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirm & Save',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
