// ─────────────────────────────────────────────────────────────────────────────
// widgets/budget_filter_chip.dart
//
// Extracted from _BudgetPageState.buildFilterChip().
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class BudgetFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const BudgetFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selectedFilter == value;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
