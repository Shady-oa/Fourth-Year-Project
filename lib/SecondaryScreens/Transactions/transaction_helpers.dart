import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Transaction helper utilities used by TransactionsPage
// ─────────────────────────────────────────────────────────────────────────────

String getDateLabel(String dateKey) {
  final date = DateFormat('dd MMM yyyy').parse(dateKey);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final txDate = DateTime(date.year, date.month, date.day);
  if (txDate == today) return 'Today';
  if (txDate == yesterday) return 'Yesterday';
  return dateKey;
}

String getTypeLabel(String type) {
  switch (type) {
    case 'income':
      return 'Income';
    case 'budget_expense':
      return 'Budget';
    case 'budget_finalized':
      return 'Budget';
    case 'savings_deduction':
      return 'Savings ↓';
    case 'savings_withdrawal':
      return 'Savings ↑';
    case 'expense':
      return 'Expense';
    default:
      return 'Other';
  }
}

/// Returns true for any transaction that must be read-only.
/// Rules:
///  • Any saving/budget type is always locked.
///  • 'expense' entries whose title starts with
///    'Saving fees (non-refundable)' are saving-fee re-logs created by
///    FinancialService.refundSavingsPrincipal — they must remain immutable
///    even after the linked goal is deleted.
bool isSavingsOrBudgetTransaction(Map<String, dynamic> tx) {
  const lockedTypes = {
    'savings_deduction',
    'saving_deposit',
    'savings_withdrawal',
    'budget_finalized',
    'budget_expense',
  };
  if (lockedTypes.contains(tx['type'] ?? '')) return true;
  final title = (tx['title'] ?? '').toString();
  if (title.startsWith('Saving fees (non-refundable)')) return true;
  return false;
}

Map<String, List<Map<String, dynamic>>> buildGroupedTransactions(
  List<Map<String, dynamic>> transactions,
) {
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (var tx in transactions) {
    final date = DateTime.parse(tx['date']);
    final dateKey = DateFormat('dd MMM yyyy').format(date);
    if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
    grouped[dateKey]!.add(tx);
  }
  return grouped;
}
