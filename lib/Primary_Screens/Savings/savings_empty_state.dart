import 'package:flutter/material.dart';

class SavingsEmptyState extends StatelessWidget {
  final String filter;
  final String search;

  const SavingsEmptyState({
    super.key,
    required this.filter,
    required this.search,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final msg = search.isNotEmpty
        ? 'No results for "$search"'
        : filter == 'active'
        ? 'No active goals'
        : filter == 'achieved'
        ? 'No achieved goals yet'
        : 'No savings goals yet';
    final sub = search.isNotEmpty
        ? 'Try a different search'
        : filter == 'active'
        ? 'All goals achieved! Create a new one.'
        : filter == 'achieved'
        ? 'Keep saving to reach your goals!'
        : 'Tap + New Goal to get started';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            msg,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
