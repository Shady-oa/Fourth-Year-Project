import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Statistics/statistics.dart';
import 'package:flutter/material.dart';

void deleteTransaction({
  required BuildContext context,
  required int index,
  required List transactions,
  required VoidCallback recalculateTotals,
  required Function(int, dynamic) restoreCallback,
}) {
  final deletedTransaction = transactions[index];
  final originalIndex = index;

  // Remove item
  transactions.removeAt(index);
  recalculateTotals();

  // Snackbar for undo
  final snackBar = SnackBar(
    dismissDirection: DismissDirection.horizontal,
    padding: paddingAllSmall,
    behavior: SnackBarBehavior.floating,
    margin: marginAllMedium,
    elevation: 4,
    backgroundColor: accentColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    content: Text(
      '${deletedTransaction.type} of ${Statistics.formatAmount(deletedTransaction.amount)} deleted. Swipe to dismiss or undo to restore.',
      style: Theme.of(context).textTheme.bodyMedium,
    ),
    duration: const Duration(seconds: 5),
    action: SnackBarAction(
      label: 'UNDO',
      textColor: Theme.of(context).colorScheme.onSurface,
      onPressed: () {
        restoreCallback(originalIndex, deletedTransaction);
        recalculateTotals();

        showCustomToast(
          context: context,
          message: 'Transaction restored successfully.',
          backgroundColor: accentColor,
          icon: Icons.undo_rounded,
        );
      },
    ),
  );

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
