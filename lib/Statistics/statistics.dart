import 'package:intl/intl.dart';

// --------------------------------------------------------------------------
// Transaction Object
// --------------------------------------------------------------------------

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

// --------------------------------------------------------------------------
// CalculationUtils Class
// --------------------------------------------------------------------------

class CalculationUtils {
  // Calculate total sum of a list of doubles
  static double calculateTotal(List<double> list) {
    return list.fold(0.0, (sum, item) => sum + item);
  }

  // Calculate net balance (Income - (Expense + Saving))
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

  // Format amount with currency
  static String formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'Ksh ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Helper to get formatted total balance
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

// --------------------------------------------------------------------------
// Statistics Class
// --------------------------------------------------------------------------

class Statistics {
  static final NumberFormat formatter = NumberFormat('#,##0.00');

  static const double income = 0;
  static const double expense = 0;
  static const double saving = 0;
  static const double budget = 0;
  static const double transaction = 0;

  // Format helper with currency prefix
  static String formatAmount(num amount) => 'Ksh ${formatter.format(amount)}';

  // Extract numeric value from number, Map, or Transaction
  static double getAmount(dynamic item) {
    if (item is num) return item.toDouble();
    if (item is Map && item.containsKey('amount')) {
      return (item['amount'] as num).toDouble();
    }
    if (item is Transaction) return item.amount;
    throw Exception(
        "Item must be a number, a Map with 'amount', or a Transaction object.");
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

  static String totalTransaction({
    List<dynamic> incomes = const [income],
    List<dynamic> expenses = const [expense],
    List<dynamic> savings = const [saving],
  }) {
    final totalIncomeAmount = calculateTotal(incomes);
    final totalExpenseAmount = calculateTotal(expenses);
    final totalSavingAmount = calculateTotal(savings);

    // Total transaction = Income + Expense + Saving
    final total = totalIncomeAmount + totalExpenseAmount + totalSavingAmount;
    return formatAmount(total);
  }

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
        totalIncomeAmount + totalSavingAmount + totalBudgetAmount - totalExpenseAmount;

    return formatAmount(balance);
  }
}
