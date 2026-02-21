import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TransactionFilterChip — filter pill used in TransactionsPage
// ─────────────────────────────────────────────────────────────────────────────

class TransactionFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String currentFilter;
  final ValueChanged<String> onSelected;

  const TransactionFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.currentFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = currentFilter == value;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha(80),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
