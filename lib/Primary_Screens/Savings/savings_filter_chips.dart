import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

class SavingsFilterChips extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const SavingsFilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _chip('All', 'all', theme),
          const SizedBox(width: 8),
          _chip('Active', 'active', theme),
          const SizedBox(width: 8),
          _chip('Achieved', 'achieved', theme),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, ThemeData theme) {
    final sel = currentFilter == value;
    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? brandGreen : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? brandGreen : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
