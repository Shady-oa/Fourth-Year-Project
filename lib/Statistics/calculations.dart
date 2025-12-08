// lib/Utils/calculation_utils.dart

import 'package:intl/intl.dart';

class Transaction {
  final String type; // Income, Expense, Saving
  final double amount;
  final String source;
  final DateTime dateTime;

  Transaction({
    required this.type,
    required this.amount,
    required this.source,
    required this.dateTime,
  });
}

class CalculationUtils {
  // Method to calculate the total sum of a list of double values
  static double calculateTotal(List<double> list) {
    return list.fold(0.0, (sum, item) => sum + item);
  }

  // Method to calculate the net balance
  static double calculateTotalBalance({
    required List<double> incomes,
    required List<double> expenses,
    required List<double> savings,
  }) {
    double totalIncome = calculateTotal(incomes);
    double totalExpense = calculateTotal(expenses);
    double totalSaving = calculateTotal(savings);
    return totalIncome - (totalExpense + totalSaving);
  }

  // Method to format a double amount into a currency string
  static String formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\Ksh ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Helper function to format the net balance as a string
  static String totalBalance({
    required List<double> incomes,
    required List<double> expenses,
    required List<double> savings,
  }) {
    double total = calculateTotalBalance(
      incomes: incomes,
      expenses: expenses,
      savings: savings,
    );
    return formatAmount(total);
  }
}
