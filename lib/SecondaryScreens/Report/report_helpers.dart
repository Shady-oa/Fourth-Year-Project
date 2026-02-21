// ─── Daily total helper ────────────────────────────────────────────────────────
class DailyTotal {
  final String day;
  final double amount;
  const DailyTotal(this.day, this.amount);
}

// ─── Transaction amount helpers ───────────────────────────────────────────────
double reportAmt(Map<String, dynamic> tx) =>
    double.tryParse(tx['amount'].toString()) ?? 0.0;

double reportFee(Map<String, dynamic> tx) =>
    double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;

// ─── Transaction type label ───────────────────────────────────────────────────
String getTypeLabel(String? type) {
  switch (type) {
    case 'income':
      return 'Income';
    case 'budget_finalized':
    case 'budget_expense':
      return 'Budget';
    case 'savings_deduction':
    case 'saving_deposit':
      return 'Savings';
    case 'expense':
      return 'Expense';
    default:
      return 'Other';
  }
}
