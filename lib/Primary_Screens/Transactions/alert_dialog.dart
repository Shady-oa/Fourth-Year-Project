import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- DATABASE FUNCTIONS ---

void addIncome(String amount, String description, BuildContext context) async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final year = DateTime.now().year.toString();
  final month = DateFormat('MM').format(DateTime.now());

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
          'name': 'Income',
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
        });

    if (!context.mounted) return;
    showCustomToast(
      context: context,
      message: 'Income added successfully!',
      backgroundColor: accentColor,
      icon: Icons.check_circle_outline_rounded,
    );
  } catch (e) {
    if (!context.mounted) return;
    showCustomToast(
      context: context,
      message: 'An error occurred while adding income.',
      backgroundColor: errorColor,
      icon: Icons.error_outline_rounded,
    );
  }
}

void addExpense(
  String amount,
  String description,
  String category,
  BuildContext context,
) async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final year = DateTime.now().year.toString();
  final month = DateFormat('MM').format(DateTime.now());

  try {
    await FirebaseFirestore.instance
        .collection('statistics')
        .doc(user.uid)
        .collection(year)
        .doc(month)
        .collection('transactions')
        .add({
          'type': 'expense',
          'amount': amount,
          'name': category,
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
        });

    if (!context.mounted) return;
    showCustomToast(
      context: context,
      message: 'Expense added successfully!',
      backgroundColor: accentColor,
      icon: Icons.check_circle_outline_rounded,
    );
  } catch (e) {
    if (!context.mounted) return;
    showCustomToast(
      context: context,
      message: 'An error occurred while adding expense.',
      backgroundColor: errorColor,
      icon: Icons.error_outline_rounded,
    );
  }
}

void addSavings(
  String amount,
  //String description,
  String category,
  BuildContext context,
) async {
  final User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final year = DateTime.now().year.toString();
  final month = DateFormat('MM').format(DateTime.now());

  try {
    await FirebaseFirestore.instance
        .collection('statistics')
        .doc(user.uid)
        .collection(year)
        .doc(month)
        .collection('transactions')
        .add({
          'type': 'saving',
          'amount': amount,
          'name': 'Savings',
          'description': category,
          'createdAt': FieldValue.serverTimestamp(),
        });

    if (!context.mounted) return;
    showCustomToast(
      context: context,
      message: 'Expense added successfully!',
      backgroundColor: accentColor,
      icon: Icons.check_circle_outline_rounded,
    );
  } catch (e) {
    if (!context.mounted) return;
    showCustomToast(
      context: context,
      message: 'An error occurred while adding expense.',
      backgroundColor: errorColor,
      icon: Icons.error_outline_rounded,
    );
  }
}

// --- UI FUNCTIONS ---

void showAddAmountDialog(BuildContext context, String type) {
  final amountController = TextEditingController();
  final sourceController = TextEditingController();
  String? selectedCategory;

  final List<String> categories = [
    'Food',
    'Transport',
    'Rent',
    'Shopping',
    'Entertainment',
    'Health',
    'Other',
  ];

  final List<String> savings = [
    'DeskTop Setup',
    'Vacation',
    'New Car',
    'Furniture',
  ];

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: radiusMedium),
          title: Text('Add $type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Amount Input
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: '0.00',
                    border: OutlineInputBorder(borderRadius: radiusMedium),
                  ),
                ),
                sizedBoxHeightSmall,

                // Description Input
                if (type == 'Income' || type == 'Expense') ...[
                  TextField(
                    controller: sourceController,
                    decoration: InputDecoration(
                      labelText: type == 'Income' ? 'Source' : 'Description',
                      hintText: type == 'Income' ? 'e.g. Salary' : 'e.g. Lunch',
                      border: OutlineInputBorder(borderRadius: radiusMedium),
                    ),
                  ),
                ],

                // Dropdown for Expense only
                if (type == 'Expense' || type == 'Savings') ...[
                  sizedBoxHeightSmall,
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    hint: const Text('Select Category'),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: radiusMedium),
                    ),
                    items: (type == 'Expense' ? categories : savings)
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedCategory = newValue;
                      });
                    },
                  ),
                ],
              ],
            ),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: radiusSmall),
              ),
              onPressed: () {
                final amountText = amountController.text.trim();
                final descriptionText = sourceController.text.trim();
                final value = double.tryParse(amountText);

                // Validation
                if (amountText.isEmpty || value == null || value <= 0) {
                  showCustomToast(
                    context: context,
                    message: 'Please enter a valid amount.',
                    backgroundColor: errorColor,
                    icon: Icons.warning_amber_rounded,
                  );
                  return;
                }

                if (type != 'Savings' && descriptionText.isEmpty) {
                  showCustomToast(
                    context: context,
                    message:
                        'Please enter a ${type == 'Income' ? 'source' : 'description'}.',
                    backgroundColor: errorColor,
                    icon: Icons.warning_amber_rounded,
                  );
                  return;
                }

                if ((type == 'Expense' && selectedCategory == null) ||
                    (type == 'Savings' && selectedCategory == null)) {
                  showCustomToast(
                    context: context,
                    message: 'Please select a category.',
                    backgroundColor: errorColor,
                    icon: Icons.category_rounded,
                  );
                  return;
                }

                // Execution
                if (type == 'Income') {
                  addIncome(amountText, descriptionText, context);
                } else if (type == 'Expense') {
                  addExpense(
                    amountText,
                    descriptionText,
                    selectedCategory!,
                    context,
                  );
                } else {
                  addSavings(
                    amountText,
                    //descriptionText,
                    selectedCategory!,
                    context,
                  );
                }

                Navigator.pop(dialogContext);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ),
  );
}
