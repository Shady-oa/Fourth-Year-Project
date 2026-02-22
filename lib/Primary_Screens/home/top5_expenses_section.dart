import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/SecondaryScreens/Report/report_page.dart';
import 'package:flutter/material.dart';

/// Displays the top-5 highest expenses ranked list.
class Top5ExpensesSection extends StatelessWidget {
  const Top5ExpensesSection({super.key, required this.top5Expenses});

  final List<Map<String, dynamic>> top5Expenses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Top 5 Expenses",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
                ),
              ),
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportPage()),
                ),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text(
                  'View All Reports',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (top5Expenses.isEmpty)
          _EmptyExpensesPlaceholder()
        else
          ...top5Expenses.asMap().entries.map((entry) {
            return _ExpenseRankTile(idx: entry.key, tx: entry.value);
          }),
      ],
    );
  }
}

class _EmptyExpensesPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 32, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'You haven\'t recorded any expenses yet.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ExpenseRankTile extends StatelessWidget {
  const _ExpenseRankTile({required this.idx, required this.tx});

  final int idx;
  final Map<String, dynamic> tx;

  static const _rankColors = [
    // populated at runtime via shade — see build()
  ];

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
    final fee =
        double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
    final total = amount + fee;

    final rankColors = [
      Colors.amber.shade400,
      Colors.grey.shade400,
      Colors.brown.shade300,
      errorColor.withOpacity(0.7),
      errorColor.withOpacity(0.5),
    ];
    final color = rankColors[idx];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${idx + 1}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title + reason
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['title'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((tx['reason'] ?? '').toString().isNotEmpty)
                  Text(
                    tx['reason'].toString(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount
          Flexible(
            flex: 0,
            child: Text(
              '- ${CurrencyFormatter.format(total)}',
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: errorColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
