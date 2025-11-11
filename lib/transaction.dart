import 'package:flutter/material.dart';

class Transaction extends StatelessWidget {
  const Transaction({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF093030),
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
            backgroundColor: isIncome ? Colors.blueAccent : Colors.greenAccent,
            child: Icon(Icons.category, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(date, style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          Spacer(),
          Text(
            amount,
            style: TextStyle(
              color: isIncome ? Colors.greenAccent : Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
