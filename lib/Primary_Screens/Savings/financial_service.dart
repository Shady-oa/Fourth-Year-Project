import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FinancialService — centralized financial recalculation
//
//  ARCHITECTURE
//  ────────────
//  SharedPreferences is the single source of truth for all financial data:
//
//    Key                 Type      Description
//    ─────────────────── ───────── ──────────────────────────────────────────
//    'transactions'      String    JSON-encoded List<Map> of all transactions
//    'total_income'      double    Running total of all income ever added
//    'budgets'           StringList JSON-encoded Budget objects
//    'savings'           StringList JSON-encoded Saving objects
//
//  EXPENSE CALCULATION
//  ───────────────────
//  totalExpenses is NEVER stored separately — it is derived on demand from the
//  transactions list. All pages that show "expenses" must use this service
//  (or call their own equivalent calculation against the same transaction list).
//
//  BALANCE FORMULA
//  ───────────────
//    balance = totalIncome - totalExpenses
//
//  Where totalExpenses includes:
//    • 'expense'            : amount + transactionCost
//    • 'budget_finalized'   : amount + transactionCost
//    • 'savings_deduction'  : amount (= savedAmount + fee, stored as one value)
//    • 'budget_expense'     : amount + transactionCost
//
//  SAVINGS DELETE LOGIC
//  ────────────────────
//    Unachieved goal deleted
//      1. Remove savings_deduction transactions   → expenses ↓ (amount + fee)
//      2. Re-log fees as 'expense'                → expenses ↑ fee
//      Net effect: expenses ↓ savedAmount, balance ↑ savedAmount
//      total_income is NOT changed.
//
//    Achieved goal deleted
//      No financial changes. Goal removed from list only.
// ─────────────────────────────────────────────────────────────────────────────

class FinancialSummary {
  final double totalIncome;
  final double totalExpenses;
  final double totalSavingsDeducted;
  final double totalFees;
  final double balance;
  final int transactionCount;

  const FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalSavingsDeducted,
    required this.totalFees,
    required this.balance,
    required this.transactionCount,
  });

  @override
  String toString() =>
      'FinancialSummary(income=$totalIncome, expenses=$totalExpenses, '
      'savings=$totalSavingsDeducted, fees=$totalFees, balance=$balance)';
}

class FinancialService {
  static const String _keyTransactions = 'transactions';
  static const String _keyTotalIncome = 'total_income';

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Reads transactions + total_income from SharedPreferences and returns a
  /// computed [FinancialSummary].  Call this after any financial mutation to
  /// get fresh totals that all pages can display consistently.
  ///
  /// Does NOT modify SharedPreferences — purely a read + compute operation.
  static Future<FinancialSummary> recalculateFinancialSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return _compute(prefs);
  }

  /// Same as [recalculateFinancialSummary] but re-uses an already-open
  /// [SharedPreferences] instance to avoid an extra disk read.
  static FinancialSummary recalculateFromPrefs(SharedPreferences prefs) =>
      _compute(prefs);

  // ── Core computation ────────────────────────────────────────────────────────

  static FinancialSummary _compute(SharedPreferences prefs) {
    final raw = prefs.getString(_keyTransactions) ?? '[]';
    final transactions =
        List<Map<String, dynamic>>.from(json.decode(raw));
    final totalIncome = prefs.getDouble(_keyTotalIncome) ?? 0.0;

    double totalExpenses = 0.0;
    double totalSavingsDeducted = 0.0;
    double totalFees = 0.0;

    for (final tx in transactions) {
      final type = (tx['type'] as String?) ?? '';
      final amount =
          double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
      final fee =
          double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;

      if (type == 'income') continue;

      totalExpenses += amount + fee;
      totalFees += fee;

      if (type == 'savings_deduction' || type == 'saving_deposit') {
        totalSavingsDeducted += amount + fee;
      }
    }

    // Guard: balance cannot go below zero
    final balance =
        (totalIncome - totalExpenses).clamp(0.0, double.infinity);

    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalSavingsDeducted: totalSavingsDeducted,
      totalFees: totalFees,
      balance: balance,
      transactionCount: transactions.length,
    );
  }

  // ── Convenience helpers ─────────────────────────────────────────────────────

  /// Removes all savings_deduction / saving_deposit transactions that belong
  /// to [goalName] and re-logs [totalFeesPaid] as a permanent 'expense' entry
  /// so that transaction fees remain in the books while only the saved
  /// principal is effectively returned to the available balance.
  ///
  /// Call this ONLY for UNACHIEVED goals being deleted.
  /// Do NOT call [adjustTotalIncome] — balance is restored purely through
  /// the transaction list (remove deductions → add fee expense).
  static Future<void> refundSavingsPrincipal({
    required String goalName,
    required double totalFeesPaid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTransactions) ?? '[]';
    final list = List<Map<String, dynamic>>.from(json.decode(raw));

    // 1. Remove savings_deduction / saving_deposit for this goal
    list.removeWhere((tx) {
      final type = tx['type'] ?? '';
      final title = (tx['title'] ?? '').toString();
      return title.contains(goalName) &&
          (type == 'savings_deduction' || type == 'saving_deposit');
    });

    // 2. Re-log fees as a permanent expense (they cannot be refunded)
    if (totalFeesPaid > 0) {
      list.insert(0, {
        'title': 'Saving fees (non-refundable): $goalName',
        'amount': totalFeesPaid,
        'transactionCost': 0.0,
        'type': 'expense',
        'reason': 'Transaction fees paid on savings deposits — non-refundable',
        'date': DateTime.now().toIso8601String(),
      });
    }

    await prefs.setString(_keyTransactions, json.encode(list));
  }

  /// Adjust [total_income] by [delta] (positive = add, negative = subtract).
  /// Use only when actual income is added, edited, or a savings withdrawal
  /// returns money directly (not for goal deletion refunds).
  static Future<void> adjustTotalIncome(double delta) async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getDouble(_keyTotalIncome) ?? 0.0;
    final updated = (cur + delta).clamp(0.0, double.infinity);
    await prefs.setDouble(_keyTotalIncome, updated);
  }
}