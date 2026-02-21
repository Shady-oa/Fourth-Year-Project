import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:flutter/material.dart';

void showTransactionToast(
    BuildContext context,
    String type,
    double amount, {
    double transactionCost = 0.0,
  }) {
    final isIncome = type == 'income';
    final action = isIncome ? 'Income Added' : 'Expense Recorded';
    final totalDeducted = amount + transactionCost;
    final msg = transactionCost > 0
        ? '$action: ${CurrencyFormatter.format(totalDeducted)} (incl. ${CurrencyFormatter.format(transactionCost)} fee)'
        : '$action: ${CurrencyFormatter.format(amount)}';
    if (isIncome) {
      AppToast.success(context, msg);
    } else {
      AppToast.error(context, msg);
    }
  }