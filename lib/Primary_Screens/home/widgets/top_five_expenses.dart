import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/SecondaryScreens/Report/report_page.dart';
import 'package:flutter/material.dart';

  List<Map<String, dynamic>> transactions = [];


List<Map<String, dynamic>> get top5Expenses {
    final expenses = transactions
        .where(
          (tx) => tx['type'] == 'expense' || tx['type'] == 'budget_finalized',
        )
        .toList();
    expenses.sort((a, b) {
      final aTotal =
          (double.tryParse(a['amount'].toString()) ?? 0) +
          (double.tryParse(a['transactionCost']?.toString() ?? '0') ?? 0);
      final bTotal =
          (double.tryParse(b['amount'].toString()) ?? 0) +
          (double.tryParse(b['transactionCost']?.toString() ?? '0') ?? 0);
      return bTotal.compareTo(aTotal);
    });
    return expenses.take(5).toList();
  }
Widget buildTop5ExpensesSection(BuildContext context) {
    final top = top5Expenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top 5 Expenses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportPage()),
                );
              },
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('View All Reports'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (top.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 32,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 12),
                Text(
                  'No expenses yet. Add some transactions!',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...top.asMap().entries.map((entry) {
            final idx = entry.key;
            final tx = entry.value;
            final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
            final fee =
                double.tryParse(tx['transactionCost']?.toString() ?? '0') ??
                0.0;
            final total = amount + fee;

            final rankColors = [
              Colors.amber.shade400,
              Colors.grey.shade400,
              Colors.brown.shade300,
              errorColor.withOpacity(0.7),
              errorColor.withOpacity(0.5),
            ];

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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rankColors[idx].withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          color: rankColors[idx],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
          }),
      ],
    );
  }