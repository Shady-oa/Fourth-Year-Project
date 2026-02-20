import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TransactionCard — Modern redesign
//
//  • Tappable card: entire surface opens action/edit bottom sheet via [onTap]
//  • No inline edit button — edit triggered by tapping the card
//  • No quotes around reason text
//  • Color-coded left accent bar + icon per transaction type
//  • Income/expense only are editable; savings & budget are read-only
// ─────────────────────────────────────────────────────────────────────────────

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final int index;
  final bool isLocked;

  /// Called when the card is tapped. Wire this to the edit/info bottom sheet.
  final VoidCallback? onTap;

  static final _numFmt = NumberFormat('#,##0', 'en_US');
  static String _ksh(double v) => 'Ksh ${_numFmt.format(v.round())}';

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.index,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tx = transaction;
    final type = (tx['type'] ?? 'expense') as String;
    final isIncome = type == 'income';
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final txCost =
        double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
    final totalDeducted = amount + txCost;
    final reason = (tx['reason'] ?? '').toString().trim();
    final date = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
    final timeStr = DateFormat('h:mm a').format(date);
    final dateStr = DateFormat('d MMM').format(date);

    final cfg = _typeConfig(type);

    final cardColor = isDark ? theme.colorScheme.surface : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.06);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: cfg.accent.withOpacity(0.08),
          highlightColor: cfg.accent.withOpacity(0.04),
          child: Ink(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left accent bar ──────────────────────────────
                    Container(width: 4, color: cfg.accent),

                    // ── Card body ────────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon badge
                            _IconBadge(
                              icon: cfg.icon,
                              accent: cfg.accent,
                              isLocked: isLocked,
                            ),

                            const SizedBox(width: 12),

                            // Middle: title + type badge + reason
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    tx['title'] ?? 'Unknown',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                      letterSpacing: -0.1,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Type badge + reason (no quotes)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: cfg.accent.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          cfg.label,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: cfg.accent,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      if (reason.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            reason, // no quotes
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: theme
                                                  .colorScheme.onSurface
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  // Fee chip
                                  if (!isIncome && txCost > 0) ...[
                                    const SizedBox(height: 5),
                                    _FeeBadge(fee: txCost, ksh: _ksh),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Right: amount + time/date
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '−'} ${_ksh(isIncome ? amount : totalDeducted)}',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: isIncome ? brandGreen : errorColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Icon badge with optional lock overlay
// ─────────────────────────────────────────────────────────────────────────────
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool isLocked;

  const _IconBadge({
    required this.icon,
    required this.accent,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Icon(icon, color: accent, size: 22)),
        ),
        if (isLocked)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child:
                  const Icon(Icons.lock, color: Colors.white, size: 10),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Fee chip
// ─────────────────────────────────────────────────────────────────────────────
class _FeeBadge extends StatelessWidget {
  final double fee;
  final String Function(double) ksh;

  const _FeeBadge({required this.fee, required this.ksh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 10, color: Colors.orange.shade700),
          const SizedBox(width: 3),
          Text(
            'Fee ${ksh(fee)}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Type config
// ─────────────────────────────────────────────────────────────────────────────
class _TypeCfg {
  final Color accent;
  final IconData icon;
  final String label;
  const _TypeCfg(this.accent, this.icon, this.label);
}

_TypeCfg _typeConfig(String type) {
  switch (type) {
    case 'income':
      return const _TypeCfg(
          brandGreen, Icons.arrow_circle_down_rounded, 'INCOME');
    case 'budget_expense':
      return _TypeCfg(
          Colors.orange.shade600, Icons.receipt_rounded, 'BUDGET');
    case 'budget_finalized':
      return const _TypeCfg(
          brandGreen, Icons.check_circle_outline, 'BUDGET ✓');
    case 'savings_deduction':
    case 'saving_deposit':
      return const _TypeCfg(
          Color(0xFF5B8AF0), Icons.savings_outlined, 'SAVINGS');
    case 'savings_withdrawal':
      return _TypeCfg(Colors.purple.shade400,
          Icons.account_balance_wallet_outlined, 'WITHDRAWAL');
    default:
      return const _TypeCfg(
          errorColor, Icons.arrow_circle_up_outlined, 'EXPENSE');
  }
}