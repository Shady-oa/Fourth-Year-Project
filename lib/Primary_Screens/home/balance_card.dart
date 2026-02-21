import 'package:final_project/Constants/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:final_project/Constants/colors.dart';


/// Displays the total balance card with income / expenses / savings stats.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.savingsTotal,
  });

  final double balance;
  final double totalIncome;
  final double totalExpenses;
  final double savingsTotal;

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isNegative
              ? [errorColor, errorColor.withOpacity(0.8)]
              : [accentColor, accentColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isNegative ? errorColor : accentColor).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Main amount
                Text(
                  CurrencyFormatter.format(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withOpacity(0.2), height: 1),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _BalanceStat(
                        label: 'Income',
                        amount: totalIncome,
                        icon: Icons.arrow_circle_down_rounded,
                      ),
                    ),
                    Container(
                        height: 36, width: 1, color: Colors.white.withOpacity(0.2)),
                    Expanded(
                      child: _BalanceStat(
                        label: 'Expenses',
                        amount: totalExpenses,
                        icon: Icons.arrow_circle_up_rounded,
                        center: true,
                      ),
                    ),
                    Container(
                        height: 36, width: 1, color: Colors.white.withOpacity(0.2)),
                    Expanded(
                      child: _BalanceStat(
                        label: 'Savings',
                        amount: savingsTotal,
                        icon: Icons.savings_outlined,
                        center: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({
    required this.label,
    required this.amount,
    required this.icon,
    this.center = false,
  });

  final String label;
  final double amount;
  final IconData icon;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              center ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.compact(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
