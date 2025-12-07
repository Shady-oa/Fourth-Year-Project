import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Statistics/statistics.dart';
import 'package:flutter/material.dart';

void showAddAmountDialog(
    BuildContext context,
    String type,
    Function(double, String) onSave,
  ) {
    final amountController = TextEditingController();
    final sourceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Amount',
                border: OutlineInputBorder(borderRadius: radiusMedium),
              ),
            ),
            sizedBoxHeightSmall,
            TextField(
              controller: sourceController,
              decoration: InputDecoration(
                hintText: (type == "Income" ? 'Source' : 'Source'),
                border: OutlineInputBorder(borderRadius: radiusMedium),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: errorColor),
            ),
          ),
          TextButton(
            onPressed: () {
              final amountText = amountController.text.trim();
              final sourceText = sourceController.text.trim();
              final value = double.tryParse(amountText);

              if (amountText.isEmpty || value == null || value <= 0) {
                Navigator.of(dialogContext).pop();
                showCustomToast(
                  context: context,
                  message:
                      'Amount field is required. Please enter a valid number greater than 0.',
                  backgroundColor: errorColor,
                  icon: Icons.error_outline_rounded,
                );
                return;
              }

              if (sourceText.isEmpty) {
                Navigator.of(dialogContext).pop();
                showCustomToast(
                  context: context,
                  message:
                      'The ${type == "Income" ? 'Source' : 'Description'} field is required.',
                  backgroundColor: errorColor,
                  icon: Icons.error_outline_rounded,
                );
                return;
              }

              onSave(value, sourceText);
              Navigator.of(dialogContext).pop();
              showCustomToast(
                context: context,
                message:
                    '$type of ${Statistics.formatAmount(value)} added successfully!',
                backgroundColor: accentColor,
                icon: Icons.check_circle_outline_rounded,
              );
            },
            child: Text(
              'Save',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }