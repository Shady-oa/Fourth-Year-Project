// ─────────────────────────────────────────────────────────────────────────────
// widgets/budget_finalized_banner.dart
//
// Extracted from the "Budget is finalized" warning banner in
// _BudgetDetailPageState.build().
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class BudgetFinalizedBanner extends StatelessWidget {
  const BudgetFinalizedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Budget is finalized. Toggle off to modify expenses.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
