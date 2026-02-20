import 'dart:convert';
import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  EditTransactionSheet
//
//  Opened by tapping a TransactionCard.
//
//  ✅ Income / Expense → full edit form
//  🔒 Budget / Savings / other → read-only detail view
//
//  Fees are NOT included in income refund when editing amounts (only the
//  net amount change is adjusted).
// ─────────────────────────────────────────────────────────────────────────────

class EditTransactionSheet extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final int index;
  final VoidCallback onSaved;

  const EditTransactionSheet({
    super.key,
    required this.transaction,
    required this.index,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> transaction,
    required int index,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => EditTransactionSheet(
        transaction: transaction,
        index: index,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _txCostCtrl;
  late TextEditingController _reasonCtrl;
  bool _isSaving = false;

  static final _numFmt = NumberFormat('#,##0', 'en_US');
  static String _ksh(double v) => 'Ksh ${_numFmt.format(v.round())}';

  String get _type => (widget.transaction['type'] ?? 'expense') as String;
  bool get _isIncome => _type == 'income';

  /// Income and expense transactions (home-page entries) are editable.
  /// All other types (savings, budget, etc.) remain read-only.
  bool get _isEditable => _type == 'income' || _type == 'expense';

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: (widget.transaction['title'] ?? '').toString(),
    );
    _amountCtrl = TextEditingController(
      text: (widget.transaction['amount'] ?? '').toString(),
    );
    _txCostCtrl = TextEditingController(
      text: (widget.transaction['transactionCost'] ?? '0').toString(),
    );
    _reasonCtrl = TextEditingController(
      text: (widget.transaction['reason'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _txCostCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final newAmount = double.tryParse(_amountCtrl.text) ?? 0;
    final txCost = double.tryParse(_txCostCtrl.text) ?? 0;
    final reason = _reasonCtrl.text.trim();

    if (title.isEmpty) {
      _snack('Please enter a transaction name');
      return;
    }
    if (newAmount <= 0) {
      _snack('Please enter a valid amount');
      return;
    }
    if (reason.isEmpty) {
      _snack('Please enter a reason');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('transactions') ?? '[]';
      final list = List<Map<String, dynamic>>.from(json.decode(raw));

      if (widget.index >= 0 && widget.index < list.length) {
        final oldAmount =
            double.tryParse(list[widget.index]['amount'].toString()) ?? 0.0;

        // Adjust total_income only for the NET amount change (fees excluded).
        if (_isIncome && oldAmount != newAmount) {
          final oldIncome = prefs.getDouble('total_income') ?? 0.0;
          await prefs.setDouble(
            'total_income',
            oldIncome + (newAmount - oldAmount),
          );
        }

        list[widget.index] = {
          ...list[widget.index],
          'title': title,
          'amount': newAmount,
          'transactionCost': _isIncome ? 0.0 : txCost,
          'reason': reason,
        };
        await prefs.setString('transactions', json.encode(list));
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction updated'),
            backgroundColor: brandGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final cfg = _typeCfg(_type);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ───────────────────────────────────────
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

            // ── Sheet header ──────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: cfg.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(cfg.icon, color: cfg.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditable
                            ? 'Edit Transaction'
                            : 'Transaction Details',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cfg.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cfg.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cfg.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Close X
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Content branch ────────────────────────────────────
            if (!_isEditable)
              _ReadOnlyView(transaction: widget.transaction, cfg: cfg)
            else ...[
              _field(
                controller: _titleCtrl,
                label: 'Transaction Name',
                icon: Icons.label_outline,
                capitalize: TextCapitalization.words,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _amountCtrl,
                label: 'Amount (Ksh)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              if (!_isIncome) ...[
                const SizedBox(height: 14),
                _field(
                  controller: _txCostCtrl,
                  label: 'Transaction Fee (Ksh)',
                  icon: Icons.receipt_outlined,
                  keyboardType: TextInputType.number,
                  hint: 'e.g. M-Pesa fee — enter 0 if none',
                ),
              ],
              const SizedBox(height: 14),
              _field(
                controller: _reasonCtrl,
                label: 'Reason',
                icon: Icons.notes_outlined,
                maxLines: 3,
                hint: 'Why this transaction?',
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cfg.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Text field helper ──────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalize = TextCapitalization.none,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalize,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Read-only detail view for savings / budget / other locked types
// ─────────────────────────────────────────────────────────────────────────────
class _ReadOnlyView extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final _SheetCfg cfg;

  static final _numFmt = NumberFormat('#,##0', 'en_US');
  static String _ksh(double v) => 'Ksh ${_numFmt.format(v.round())}';

  const _ReadOnlyView({required this.transaction, required this.cfg});

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
    final txCost =
        double.tryParse(transaction['transactionCost']?.toString() ?? '0') ??
        0.0;
    final reason = (transaction['reason'] ?? '').toString().trim();
    final date = DateTime.tryParse(transaction['date'] ?? '') ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lock notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This is a read-only transaction record. Transactions cannot be modified from this screen.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Detail rows
        _row(context, 'Name', transaction['title'] ?? '—'),
        _row(context, 'Amount', _ksh(amount)),
        if (txCost > 0) _row(context, 'Fee', _ksh(txCost)),
        _row(context, 'Total', _ksh(amount + txCost), bold: true),
        if (reason.isNotEmpty) _row(context, 'Reason', reason),
        _row(context, 'Date', DateFormat('d MMM yyyy · h:mm a').format(date)),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Sheet visual config per type
// ─────────────────────────────────────────────────────────────────────────────
class _SheetCfg {
  final Color accent;
  final IconData icon;
  final String label;
  const _SheetCfg(this.accent, this.icon, this.label);
}

_SheetCfg _typeCfg(String type) {
  switch (type) {
    case 'income':
      return const _SheetCfg(
        brandGreen,
        Icons.arrow_circle_down_rounded,
        'Income',
      );
    case 'expense':
      return const _SheetCfg(
        errorColor,
        Icons.arrow_circle_up_outlined,
        'Expense',
      );
    case 'budget_expense':
      return _SheetCfg(
        Colors.orange.shade600,
        Icons.receipt_rounded,
        'Budget Expense',
      );
    case 'budget_finalized':
      return const _SheetCfg(
        brandGreen,
        Icons.check_circle_outline,
        'Budget Finalised',
      );
    case 'savings_deduction':
    case 'saving_deposit':
      return const _SheetCfg(
        Color(0xFF5B8AF0),
        Icons.savings_outlined,
        'Savings Deposit',
      );
    case 'savings_withdrawal':
      return _SheetCfg(
        Colors.purple.shade400,
        Icons.account_balance_wallet_outlined,
        'Savings Withdrawal',
      );
    default:
      return const _SheetCfg(
        errorColor,
        Icons.arrow_circle_up_outlined,
        'Transaction',
      );
  }
}
