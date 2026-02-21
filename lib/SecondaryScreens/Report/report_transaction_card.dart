import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/SecondaryScreens/Report/report_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


// ─── Transaction Card ─────────────────────────────────────────────────────────
class ReportTransactionCard extends StatelessWidget {
  final Map<String, dynamic> tx;

  const ReportTransactionCard({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = tx['type'] == 'income';
    final amount = reportAmt(tx);
    final fee = reportFee(tx);
    final date = DateTime.parse(tx['date']);
    final total = isIncome ? amount : amount + fee;

    IconData icon;
    Color iconColor;
    switch (tx['type']) {
      case 'income':
        icon = Icons.arrow_circle_down_rounded;
        iconColor = brandGreen;
        break;
      case 'budget_finalized':
        icon = Icons.check_circle;
        iconColor = accentColor;
        break;
      case 'savings_deduction':
      case 'saving_deposit':
        icon = Icons.savings;
        iconColor = brandGreen;
        break;
      default:
        icon = Icons.arrow_circle_up_rounded;
        iconColor = errorColor;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['title'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      DateFormat('HH:mm').format(date),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (fee > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+fee',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  getTypeLabel(tx['type']),
                  style: TextStyle(
                    fontSize: 10,
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isIncome ? '+' : '-'} ${CurrencyFormatter.format(total)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isIncome ? brandGreen : errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
