import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:flutter/material.dart';



// ─── Filters Row ──────────────────────────────────────────────────────────────
class ReportFiltersRow extends StatelessWidget {
  final String? selectedType;
  final String? selectedBudget;
  final String? selectedSaving;
  final List<Budget> budgets;
  final List<Saving> savings;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onBudgetChanged;
  final ValueChanged<String?> onSavingChanged;

  const ReportFiltersRow({
    super.key,
    required this.selectedType,
    required this.selectedBudget,
    required this.selectedSaving,
    required this.budgets,
    required this.savings,
    required this.onTypeChanged,
    required this.onBudgetChanged,
    required this.onSavingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            theme,
            'Type',
            selectedType,
            ['All', 'Income', 'Expense', 'Savings'],
            onTypeChanged,
          ),
        ),
        if (budgets.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildDropdown(
              theme,
              'Budget',
              selectedBudget,
              ['All', ...budgets.map((b) => b.name)],
              onBudgetChanged,
            ),
          ),
        ],
        if (savings.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildDropdown(
              theme,
              'Goal',
              selectedSaving,
              ['All', ...savings.map((s) => s.name)],
              onSavingChanged,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown(
    ThemeData theme,
    String hint,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12)),
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
