import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SelectableTransactionCard — shown only during multi-select mode
// ─────────────────────────────────────────────────────────────────────────────

class SelectableTransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isSelected;
  final VoidCallback onToggle;

  const SelectableTransactionCard({
    super.key,
    required this.transaction,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (transaction['title'] ?? 'Transaction').toString();
    final amount =
        double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
    final type = (transaction['type'] ?? 'expense').toString();
    final isIncome = type == 'income';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.red.withOpacity(0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.red.shade300
                  : theme.colorScheme.onSurface.withOpacity(0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color:
                      isSelected ? Colors.red.shade400 : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? Colors.red.shade400
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 14),
              // Title
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isSelected ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Amount
              Text(
                '${isIncome ? '+' : '-'} Ksh ${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIncome
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
