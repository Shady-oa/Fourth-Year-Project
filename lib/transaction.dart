import 'package:final_project/constants.dart';
import 'package:flutter/material.dart';

class Transaction extends StatelessWidget {
  const Transaction({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: primaryText,
      body: SingleChildScrollView(
        child: Column(
          children: [
            TransactionItem(
              title: 'food',
              date: '12/2/2025',
              amount: '400',
              isIncome: true,
            ),
            TransactionItem(title: 'food', date: '12/2/2025', amount: '400'),
            TransactionItem(
              title: 'food',
              date: '12/2/2025',
              amount: '400',
              isIncome: true,
            ),
            TransactionItem(title: 'food', date: '12/2/2025', amount: '400'),
            TransactionItem(
              title: 'food',
              date: '12/2/2025',
              amount: '400',
              isIncome: true,
            ),
            TransactionItem(title: 'food', date: '12/2/2025', amount: '400'),
            TransactionItem(
              title: 'food',
              date: '12/2/2025',
              amount: '400',
              isIncome: true,
            ),
            TransactionItem(title: 'food', date: '12/2/2025', amount: '400'),
            TransactionItem(
              title: 'food',
              date: '12/2/2025',
              amount: '400',
              isIncome: true,
            ),
            TransactionItem(title: 'food', date: '12/2/2025', amount: '400'),
          ],
        ),
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  //final IconData icon;
  final String title;
  final String date;
  final String amount;
  final bool isIncome;

  const TransactionItem({
    super.key,
    //required this.icon,
    required this.title,
    required this.date,
    required this.amount,
    this.isIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isIncome ? brandGreen : Colors.red,
            child: const Icon(Icons.category, color: primaryText),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: kTextTheme.bodyLarge?.copyWith(color: primaryBg),
              ),
              Text(date,
                  style: kTextTheme.bodySmall
                      ?.copyWith(color: primaryBg.withOpacity(0.7))),
            ],
          ),
          const Spacer(),
          Text(
            amount,
            style: kTextTheme.bodyLarge?.copyWith(
              color: isIncome ? brandGreen : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
