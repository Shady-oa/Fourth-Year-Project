import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void addIncome(String amount, String description, BuildContext context) async {
  final User user = FirebaseAuth.instance.currentUser!;
  final year = DateTime.now().year.toString();
  final month = DateTime.now().month.toString();

  try {
    await FirebaseFirestore.instance
        .collection('statistics')
        .doc(user.uid)
        .collection(year)
        .doc(month)
        .collection('transactions')
        .add({
          'type': 'income',
          'amount': amount,
          'name': 'income',
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
        });

    showCustomToast(
      context: context,
      message: 'Income added successfully!',
      backgroundColor: accentColor,
      icon: Icons.check_circle_outline_rounded,
    );
  } catch (e) {
    showCustomToast(
      context: context,
      message: 'An error Occurred!',
      backgroundColor: errorColor,
      icon: Icons.check_circle_outline_rounded,
    );
  }
}

void showAddAmountDialog(
  BuildContext context,
  String type,
  // Function(double, String) onSave,
) {
  final amountController = TextEditingController();
  final sourceController = TextEditingController();

  if (type == 'Income') {
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
                hintText: 'Source',
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
                  message: 'The Income source field is required.',
                  backgroundColor: errorColor,
                  icon: Icons.error_outline_rounded,
                );
                return;
              }

              addIncome(amountText, sourceText, context);
              Navigator.pop(context);
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
  } else if (type == 'Expense') {
  } else {}
}
