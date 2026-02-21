import 'package:final_project/Constants/colors.dart';
import 'package:final_project/SecondaryScreens/Transactions/edit_transaction.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TransactionDetailSheet
//
//  Shown when the user taps any transaction card.  For income/expense (editable)
//  an Edit button is presented.  For locked types only a Close button is shown.
// ─────────────────────────────────────────────────────────────────────────────

class TransactionDetailSheet {
  static void show(
    BuildContext ctx,
    Map<String, dynamic> tx,
    int displayIndex,
    bool locked,
    VoidCallback onRefresh,
  ) {
    final type = (tx['type'] ?? 'expense') as String;
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final txCost =
        double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
    final reason = (tx['reason'] ?? '').toString().trim();
    final date = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
    final title = (tx['title'] ?? '—').toString();

    Color accent;
    IconData typeIcon;
    switch (type) {
      case 'income':
        accent = accentColor;
        typeIcon = Icons.arrow_circle_down_rounded;
        break;
      case 'expense':
        accent = errorColor;
        typeIcon = Icons.arrow_circle_up_outlined;
        break;
      case 'budget_expense':
      case 'budget_finalized':
        accent = Colors.orange.shade600;
        typeIcon = Icons.receipt_rounded;
        break;
      case 'savings_deduction':
      case 'saving_deposit':
        accent = const Color(0xFF5B8AF0);
        typeIcon = Icons.savings_outlined;
        break;
      case 'savings_withdrawal':
        accent = Colors.purple.shade400;
        typeIcon = Icons.account_balance_wallet_outlined;
        break;
      default:
        accent = errorColor;
        typeIcon = Icons.receipt_outlined;
    }

    final typeLabel = _getTypeLabel(type);
    final numFmt = NumberFormat('#,##0', 'en_US');
    String ksh(double v) => 'Ksh ${numFmt.format(v.round())}';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(sheetCtx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 28,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header row
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(typeIcon, color: accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transaction Details',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(sheetCtx)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Detail rows
              _detailRow(sheetCtx, 'Name', title),
              _detailRow(sheetCtx, 'Amount', ksh(amount)),
              if (txCost > 0)
                _detailRow(
                  sheetCtx,
                  'Fee',
                  ksh(txCost),
                  valueColor: Colors.orange,
                ),
              if (txCost > 0)
                _detailRow(sheetCtx, 'Total', ksh(amount + txCost),
                    bold: true),
              if (reason.isNotEmpty) _detailRow(sheetCtx, 'Reason', reason),
              _detailRow(
                sheetCtx,
                'Date',
                DateFormat('d MMM yyyy · h:mm a').format(date),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  if (!locked) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          EditTransactionSheet.show(
                            ctx,
                            transaction: tx,
                            index: displayIndex,
                            onSaved: onRefresh,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _getTypeLabel(String type) {
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
}
