import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:final_project/SecondaryScreens/Report/date_preset.dart';
import 'package:final_project/SecondaryScreens/Report/report_helpers.dart';
import 'package:flutter/material.dart';



// ─── Key Insights Section ─────────────────────────────────────────────────────
class ReportInsightsSection extends StatelessWidget {
  final double filteredExpenses;
  final double priorExpenses;
  final DatePreset selectedPreset;
  final double projectedMonthEndSpend;
  final Map<String, dynamic>? biggestExpense;
  final List<Saving> savings;
  final double totalFeesPaid;

  const ReportInsightsSection({
    super.key,
    required this.filteredExpenses,
    required this.priorExpenses,
    required this.selectedPreset,
    required this.projectedMonthEndSpend,
    required this.biggestExpense,
    required this.savings,
    required this.totalFeesPaid,
  });

  @override
  Widget build(BuildContext context) {
    final insights = <Map<String, dynamic>>[];

    if (priorExpenses > 0) {
      final changePct = ((filteredExpenses - priorExpenses) / priorExpenses) * 100;
      insights.add({
        'icon': changePct > 0 ? Icons.trending_up : Icons.trending_down,
        'color': changePct > 0 ? errorColor : brandGreen,
        'title': changePct > 0 ? 'Spending Increased' : 'Spending Decreased',
        'subtitle': '${changePct.abs().toStringAsFixed(1)}% vs prior period',
      });
    }
    if (selectedPreset == DatePreset.thisMonth) {
      insights.add({
        'icon': Icons.auto_graph,
        'color': Colors.purple,
        'title': 'Projected Month-End Spend',
        'subtitle': CurrencyFormatter.format(projectedMonthEndSpend),
      });
    }
    if (biggestExpense != null) {
      insights.add({
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orange,
        'title': 'Largest Expense',
        'subtitle':
            '${biggestExpense!['title']} · ${CurrencyFormatter.format(reportAmt(biggestExpense!) + reportFee(biggestExpense!))}',
      });
    }
    for (final s in savings) {
      if (!s.achieved && s.progressPercent > 0.8) {
        insights.add({
          'icon': Icons.flag_rounded,
          'color': brandGreen,
          'title':
              '${(s.progressPercent * 100).toStringAsFixed(0)}% to goal: ${s.name}',
          'subtitle':
              '${CurrencyFormatter.format(s.savedAmount)} / ${CurrencyFormatter.format(s.targetAmount)}',
        });
      }
    }
    if (filteredExpenses > 0 && totalFeesPaid > filteredExpenses * 0.05) {
      insights.add({
        'icon': Icons.receipt_outlined,
        'color': Colors.orange,
        'title': 'High Transaction Fees',
        'subtitle':
            '${CurrencyFormatter.format(totalFeesPaid)} in fees (${(totalFeesPaid / filteredExpenses * 100).toStringAsFixed(1)}% of spend)',
      });
    }
    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.lightbulb_outline,
        'color': accentColor,
        'title': 'Keep going!',
        'subtitle': 'Add more transactions to unlock insights.',
      });
    }

    return Column(
      children: insights.map((insight) {
        final color = insight['color'] as Color;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  insight['icon'] as IconData,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight['title'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insight['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
