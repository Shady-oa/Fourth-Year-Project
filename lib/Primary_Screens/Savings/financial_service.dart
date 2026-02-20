import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FinancialService — single source of truth for ALL financial calculations.
//
//  ARCHITECTURE
//  ────────────
//  SharedPreferences keys:
//    'transactions'  String   JSON-encoded List<Map> of all transactions
//    'total_income'  double   Running total of all income ever added
//    'budgets'       StringList
//    'savings'       StringList
//
//  TRANSACTION TYPES & EXPENSE TREATMENT
//  ──────────────────────────────────────
//    'income'             → NOT an expense (skipped)
//    'expense'            → totalExpenses += amount + transactionCost
//    'budget_expense'     → totalExpenses += amount + transactionCost
//    'budget_finalized'   → totalExpenses += amount + transactionCost
//    'savings_deduction'  → totalExpenses += amount  (amount already = principal +
//    'saving_deposit'       fee, stored as one value; _fee is also stored but
//                           is the fee portion inside 'amount'; do NOT add again)
//    'savings_withdrawal' → NEUTRAL — does NOT add to expenses.
//                           These entries are kept for the transaction history
//                           display only. The withdrawal effect on balance is
//                           achieved by removing the matching savings_deduction
//                           entries from the list (done in _removeFunds).
//
//  BALANCE FORMULA
//  ───────────────
//    balance = total_income − totalExpenses   (clamped to ≥ 0)
//
//  SAVINGS DELETE LOGIC (unachieved goal)
//  ───────────────────────────────────────
//    1. Remove all savings_deduction / saving_deposit rows for goal.
//       → expenses drop by (savedPrincipal + fees)
//    2. Re-log fees as a permanent 'expense'.
//       → expenses rise back by fees
//    Net: expenses drop by savedPrincipal, balance rises by savedPrincipal.
//    total_income is NEVER modified by savings operations.
//
//  SAVINGS WITHDRAW LOGIC
//  ──────────────────────
//    When user withdraws X from a goal:
//    1. Remove savings_deduction rows proportionally (FIFO/newest-first).
//       → expenses drop by X + proportional_fees_removed
//    2. Re-log any removed fees that correspond to the removed deductions as
//       permanent 'expense' entries so fees are never refunded.
//    3. Log a 'savings_withdrawal' entry for display purposes only (no $effect).
//    The 'savings_withdrawal' type is skipped by _compute().
// ─────────────────────────────────────────────────────────────────────────────

class FinancialSummary {
  final double totalIncome;

  /// Total expenses including saving deposits and fees.
  final double totalExpenses;

  /// Combined principal+fee amount deducted for savings (for internal use).
  final double totalSavingsDeducted;

  /// Displayed savings amount — principal only, NO fees.
  /// Use this everywhere a "Saved" stat is shown.
  final double displayedSavingsAmount;

  final double totalFees;
  final double balance;
  final int transactionCount;

  const FinancialSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalSavingsDeducted,
    required this.displayedSavingsAmount,
    required this.totalFees,
    required this.balance,
    required this.transactionCount,
  });

  @override
  String toString() =>
      'FinancialSummary(income=$totalIncome, expenses=$totalExpenses, '
      'savings=$totalSavingsDeducted, displayedSavings=$displayedSavingsAmount, '
      'fees=$totalFees, balance=$balance)';
}

class FinancialService {
  static const String _keyTransactions = 'transactions';
  static const String _keyTotalIncome = 'total_income';

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Reads transactions + total_income from SharedPreferences and returns a
  /// computed [FinancialSummary].
  ///
  /// Call this after any financial mutation to get fresh totals that all pages
  /// can display consistently.  Pure read + compute — does NOT write to prefs.
  static Future<FinancialSummary> getFinancialSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return _compute(prefs);
  }

  /// Alias retained for backwards compatibility.
  static Future<FinancialSummary> recalculateFinancialSummary() =>
      getFinancialSummary();

  /// Same as [getFinancialSummary] but re-uses an already-open
  /// [SharedPreferences] instance to avoid an extra disk read.
  static FinancialSummary recalculateFromPrefs(SharedPreferences prefs) =>
      _compute(prefs);

  // ── Core computation ────────────────────────────────────────────────────────

  static FinancialSummary _compute(SharedPreferences prefs) {
    final raw = prefs.getString(_keyTransactions) ?? '[]';
    final transactions = List<Map<String, dynamic>>.from(json.decode(raw));
    final totalIncome = prefs.getDouble(_keyTotalIncome) ?? 0.0;

    double totalExpenses = 0.0;
    double totalSavingsDeducted = 0.0;
    double displayedSavingsAmount = 0.0;
    double totalFees = 0.0;

    for (final tx in transactions) {
      final type = (tx['type'] as String?) ?? '';
      final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
      final fee =
          double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;

      switch (type) {
        // ── Income: never an expense ──────────────────────────────────────────
        case 'income':
          break;

        // ── Savings withdrawal: display-only, no financial effect ─────────────
        // The matching savings_deduction rows were already removed when
        // _removeFunds ran its transaction-list surgery.
        case 'savings_withdrawal':
          break;

        // ── Savings deposits ──────────────────────────────────────────────────
        // 'amount' stored = principal + fee (totalDeduct).
        // 'transactionCost' stored = fee portion only.
        // displayedSavingsAmount = principal = amount − fee.
        case 'savings_deduction':
        case 'saving_deposit':
          totalExpenses += amount; // amount already includes fee
          totalFees += fee;
          totalSavingsDeducted += amount;
          // principal only (no fee) for the stats card
          displayedSavingsAmount += (amount - fee).clamp(0.0, double.infinity);
          break;

        // ── All other expense types ───────────────────────────────────────────
        default:
          totalExpenses += amount + fee;
          totalFees += fee;
          break;
      }
    }

    final balance = (totalIncome - totalExpenses).clamp(0.0, double.infinity);

    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalSavingsDeducted: totalSavingsDeducted,
      displayedSavingsAmount: displayedSavingsAmount.clamp(
        0.0,
        double.infinity,
      ),
      totalFees: totalFees,
      balance: balance,
      transactionCount: transactions.length,
    );
  }

  // ── Deletion helper ─────────────────────────────────────────────────────────

  /// For UNACHIEVED goal deletion:
  /// 1. Removes all savings_deduction / saving_deposit rows for [goalName].
  /// 2. Re-logs [totalFeesPaid] as a non-refundable 'expense' so that fees
  ///    remain permanently in the books.
  ///
  /// Net effect: expenses drop by the saved principal, balance rises by the
  ///             same amount.  total_income is NEVER changed.
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

    // 2. Re-log fees as a permanent non-refundable expense
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

  // ── Withdrawal helper ───────────────────────────────────────────────────────

  /// For savings WITHDRAWALS (remove-funds, not goal deletion):
  ///
  /// Removes savings_deduction rows for [goalName] (newest-first) until the
  /// cumulative principal removed equals [withdrawAmount]. Any fees attached to
  /// those removed rows are re-logged as non-refundable expenses.
  ///
  /// A display-only 'savings_withdrawal' row is appended so the transaction
  /// history shows the event, but _compute() ignores this type.
  ///
  /// total_income is NEVER modified.
  static Future<void> processWithdrawal({
    required String goalName,
    required double withdrawAmount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTransactions) ?? '[]';
    final list = List<Map<String, dynamic>>.from(json.decode(raw));

    // Collect savings_deduction rows for this goal, newest-first (already
    // stored newest-first in the list, so we iterate forward).
    final deductionIndices = <int>[];
    for (var i = 0; i < list.length; i++) {
      final tx = list[i];
      final type = (tx['type'] ?? '') as String;
      final title = (tx['title'] ?? '').toString();
      if (title.contains(goalName) &&
          (type == 'savings_deduction' || type == 'saving_deposit')) {
        deductionIndices.add(i);
      }
    }

    double remainingToRemove = withdrawAmount;
    double feesReleased = 0.0;
    final toDelete = <int>[];

    for (final idx in deductionIndices) {
      if (remainingToRemove <= 0) break;
      final tx = list[idx];
      final storedAmount =
          double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
      final storedFee =
          double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
      final principal = storedAmount - storedFee; // what was actually saved

      if (principal <= remainingToRemove) {
        // Remove this deduction entirely
        toDelete.add(idx);
        remainingToRemove -= principal;
        feesReleased += storedFee;
      } else {
        // Partial removal: reduce the deduction row in-place
        final newPrincipal = principal - remainingToRemove;
        final proportionalFee = storedFee > 0 && principal > 0
            ? storedFee * (remainingToRemove / principal)
            : 0.0;
        feesReleased += proportionalFee;
        list[idx] = {
          ...tx,
          'amount': newPrincipal + (storedFee - proportionalFee),
          'transactionCost': storedFee - proportionalFee,
        };
        remainingToRemove = 0;
      }
    }

    // Delete in reverse index order to preserve positions
    for (final idx in toDelete.reversed) {
      list.removeAt(idx);
    }

    // Re-log released fees as permanent non-refundable expenses
    if (feesReleased > 0) {
      list.insert(0, {
        'title': 'Saving fees (non-refundable): $goalName',
        'amount': feesReleased,
        'transactionCost': 0.0,
        'type': 'expense',
        'reason':
            'Transaction fees on withdrawn savings deposit — non-refundable',
        'date': DateTime.now().toIso8601String(),
      });
    }

    // Display-only withdrawal record (skipped by _compute)
    list.insert(0, {
      'title': 'Withdrawal from $goalName',
      'amount': withdrawAmount,
      'transactionCost': 0.0,
      'type': 'savings_withdrawal',
      'reason': 'Savings withdrawn back to available balance',
      'date': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_keyTransactions, json.encode(list));
  }

  // ── Income helper ───────────────────────────────────────────────────────────

  /// Adjust [total_income] by [delta] (positive = add, negative = subtract).
  /// ONLY call this when actual income is added or edited manually.
  /// NEVER call for savings operations.
  static Future<void> adjustTotalIncome(double delta) async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getDouble(_keyTotalIncome) ?? 0.0;
    final updated = (cur + delta).clamp(0.0, double.infinity);
    await prefs.setDouble(_keyTotalIncome, updated);
  }
}
