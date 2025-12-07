// ignore_for_file: prefer_const_constructors

import 'package:intl/intl.dart';

class Statistics {
  // Formatter: comma-separated numbers
  static final NumberFormat formatter = NumberFormat('#,##0.00');

  // Default values
  static const double income = 0;
  static const double expense = 0;
  static const double saving = 0;
  static const double budget = 0;
  static const double transaction = 0;

  // Format helper with currency prefix
  static String formatAmount(num amount) => 'Ksh ${formatter.format(amount)}';

  // Extract numeric value from num or {"amount": value}
  static double getAmount(dynamic item) {
    if (item is num) return item.toDouble();
    if (item is Map && item.containsKey('amount')) {
      return (item['amount'] as num).toDouble();
    }
    throw Exception("Item must be a number or a Map with 'amount'.");
  }

  // Calculate total from a list
  static double calculateTotal(List<dynamic> list) =>
      list.fold(0.0, (total, item) => total + getAmount(item));

  // ---- Income ----
  static String singleIncome([double amount = income]) => formatAmount(amount);
  static String totalIncome([List<dynamic> incomeList = const [income]]) =>
      formatAmount(calculateTotal(incomeList));

  // ---- Expense ----
  static String singleExpense([double amount = expense]) =>
      formatAmount(amount);
  static String totalExpense([List<dynamic> expenseList = const [expense]]) =>
      formatAmount(calculateTotal(expenseList));

  // ---- Saving ----
  static String singleSaving([double amount = saving]) => formatAmount(amount);
  static String totalSaving([List<dynamic> savingList = const [saving]]) =>
      formatAmount(calculateTotal(savingList));

  // ---- Budget ----
  static String singleBudget([double amount = budget]) => formatAmount(amount);
  static String totalBudget([List<dynamic> budgetList = const [budget]]) =>
      formatAmount(calculateTotal(budgetList));

  // ---- Transaction ----
  static String singleTransaction([double amount = transaction]) =>
      formatAmount(amount);
  static String totalTransaction([
    List<dynamic> transactionList = const [transaction],
  ]) => formatAmount(calculateTotal(transactionList));

  // ---- Total Balance ----
  static String totalBalance({
    List<dynamic> incomes = const [income],
    List<dynamic> expenses = const [expense],
    List<dynamic> savings = const [saving],
    List<dynamic> budgets = const [budget],
  }) {
    final totalIncomeAmount = calculateTotal(incomes);
    final totalExpenseAmount = calculateTotal(expenses);
    final totalSavingAmount = calculateTotal(savings);
    final totalBudgetAmount = calculateTotal(budgets);

    final balance =
        totalIncomeAmount +
        totalSavingAmount +
        totalBudgetAmount -
        totalExpenseAmount;

    return formatAmount(balance);
  }
}
