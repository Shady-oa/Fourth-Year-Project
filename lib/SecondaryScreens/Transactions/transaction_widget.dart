import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/SecondaryScreens/Transactions/undo_transaction.dart';
import 'package:final_project/Statistics/statistics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Widget buildEmptyTransactions(BuildContext context) {
  return Center(
    child: Column(
      children: [
        sizedBoxHeightLarge,
        Icon(
          Icons.receipt_long_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
        sizedBoxHeightSmall,
        Text(
          'No recent transactions found.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    ),
  );
}

Widget buildRecentTransactions({
  required BuildContext context,
  required List<Transaction> recentTransactions,
  required List<Transaction> transactions,
  required VoidCallback recalculateTotals,
  required Function(List<Transaction>) updateTransactions,
}) {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: recentTransactions.length,
    itemBuilder: (context, index) {
      final tx = recentTransactions[index];
      final originalIndex = transactions.indexOf(tx);

      // Determine text color by type
      Color typeColor;
      switch (tx.type) {
        case "Income":
          typeColor = accentColor;
          break;
        case "Expense":
          typeColor = errorColor;
          break;
        case "Saving":
          typeColor = brandGreen;
          break;
        default:
          typeColor = Theme.of(context).colorScheme.onSurface;
      }

      String formattedDate = DateFormat(
        'EEE, MMM d, yyyy – HH:mm',
      ).format(tx.dateTime);

      return Dismissible(
        key: Key(tx.dateTime.toIso8601String()),
        direction: DismissDirection.endToStart,

        onDismissed: (_) {
          deleteTransaction(
            context: context,
            index: originalIndex,
            transactions: transactions,
            recalculateTotals: recalculateTotals,
            restoreCallback: (i, item) {
              if (i <= transactions.length) {
                transactions.insert(i, item);
              } else {
                transactions.insert(0, item);
              }

              updateTransactions(transactions);
            },
          );

          updateTransactions(transactions);
        },

        // DELETE BACKGROUND UI
        background: Container(
          margin: marginAllTiny,
          padding: paddingAllMedium,
          decoration: BoxDecoration(
            color: errorColor,
            borderRadius: radiusMedium,
          ),
          alignment: Alignment.centerRight,
          child: const Icon(
            Icons.delete_forever_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),

        // TRANSACTION CARD
        child: Container(
          margin: marginAllTiny,
          padding: paddingAllMedium,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: radiusMedium,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                blurRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT SIDE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.type,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.source,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // RIGHT SIDE
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Statistics.formatAmount(tx.amount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
