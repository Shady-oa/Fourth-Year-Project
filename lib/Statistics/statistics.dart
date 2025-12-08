import 'package:intl/intl.dart';


// --------------------------------------------------------------------------
// GLOBAL VARIABLES FOR BACKEND SYNC
// --------------------------------------------------------------------------

double totalIncomeValue = 0.0;
double totalExpenseValue = 0.0;
double totalSavingValue = 0.0;
double totalBudgetValue = 0.0;
double totalTransactionValue = 0.0;     // Income + Expense + Saving
double totalBalanceValue = 0.0;         // Income + Saving + Budget - Expense



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

  static String totalIncome([List<dynamic> incomeList = const [income]]) {
    totalIncomeValue = calculateTotal(incomeList);   // 🔥 Update global value
    return formatAmount(totalIncomeValue);
  }



  // ---- Expense ----
  static String singleExpense([double amount = expense]) =>
      formatAmount(amount);

  static String totalExpense([List<dynamic> expenseList = const [expense]]) {
    totalExpenseValue = calculateTotal(expenseList);  // 🔥 Update global value
    return formatAmount(totalExpenseValue);
  }



  // ---- Saving ----
  static String singleSaving([double amount = saving]) => formatAmount(amount);

  static String totalSaving([List<dynamic> savingList = const [saving]]) {
    totalSavingValue = calculateTotal(savingList);    // 🔥 Update global
    return formatAmount(totalSavingValue);
  }



  // ---- Budget ----
  static String singleBudget([double amount = budget]) => formatAmount(amount);

  static String totalBudget([List<dynamic> budgetList = const [budget]]) {
    totalBudgetValue = calculateTotal(budgetList);    // 🔥 Update global
    return formatAmount(totalBudgetValue);
  }



  // ---- Total Transactions (Income + Expense + Saving) ----
  static String totalTransaction({
    List<dynamic> incomes = const [income],
    List<dynamic> expenses = const [expense],
    List<dynamic> savings = const [saving],
  }) {
    final totalIncomeAmount = calculateTotal(incomes);
    final totalExpenseAmount = calculateTotal(expenses);
    final totalSavingAmount = calculateTotal(savings);

    totalTransactionValue =
        totalIncomeAmount + totalExpenseAmount + totalSavingAmount;   // 🔥 Update global

    return formatAmount(totalTransactionValue);
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

    totalBalanceValue =
        totalIncomeAmount + totalSavingAmount + totalBudgetAmount - totalExpenseAmount;  // 🔥 Update global

    return formatAmount(totalBalanceValue);
  }
}
