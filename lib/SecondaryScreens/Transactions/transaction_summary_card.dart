import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Savings/financial_service.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TransactionSummaryCard
//
//  Matches the Home page balance-card style (gradient, same typography).
//  Shows ONLY Income and Expenses — Balance and Saved are shown on Home page.
// ─────────────────────────────────────────────────────────────────────────────

class TransactionSummaryCard extends StatelessWidget {
  final FinancialSummary? summary;

  const TransactionSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final income = s?.totalIncome ?? 0.0;
    final expenses = s?.totalExpenses ?? 0.0;
    final isOverspent = expenses > income;

    final gradientStart = isOverspent ? errorColor : accentColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [gradientStart, gradientStart.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles — same as Home page balance card
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -16,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: _buildStat(
                    label: 'Total Income',
                    amount: income,
                    icon: Icons.arrow_circle_down_rounded,
                    alignLeft: true,
                  ),
                ),
                Container(
                  height: 44,
                  width: 1,
                  color: Colors.white.withOpacity(0.25),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildStat(
                    label: 'Total Expenses',
                    amount: expenses,
                    icon: Icons.arrow_circle_up_rounded,
                    alignLeft: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required double amount,
    required IconData icon,
    required bool alignLeft,
  }) {
    return Column(
      crossAxisAlignment:
          alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment:
              alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (alignLeft) ...[
              Icon(icon, color: Colors.white70, size: 13),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!alignLeft) ...[
              const SizedBox(width: 5),
              Icon(icon, color: Colors.white70, size: 13),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
