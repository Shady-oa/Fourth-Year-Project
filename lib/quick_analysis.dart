import 'package:final_project/constants.dart';
import 'package:flutter/material.dart';

class QuickAnalysis extends StatefulWidget {
  const QuickAnalysis({super.key});

  @override
  State<QuickAnalysis> createState() => _QuickAnalysisState();
}

class _QuickAnalysisState extends State<QuickAnalysis> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.arrow_back, color: primaryText),
                  ),
                  const Spacer(),
                  Text(
                    'Quickly Analysis',
                    style: kTextTheme.headlineSmall,
                  ),
                  const Spacer(),
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: primaryText,
                    child: Icon(
                      Icons.notifications_outlined,
                      color: primaryBg,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: primaryText,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Savings On Goals',
                        style: kTextTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Revenue Last Week',
                        style: kTextTheme.bodyMedium
                            ?.copyWith(color: brandGreen),
                      ),
                      Text(
                        '\$4,000.00',
                        style: kTextTheme.bodyLarge,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Food Last Week',
                        style: kTextTheme.bodyMedium
                            ?.copyWith(color: brandGreen),
                      ),
                      Text(
                        '-\$100.00',
                        style: kTextTheme.bodyLarge
                            ?.copyWith(color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  color: primaryText,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: primaryBg,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                            child: Text('Graph', style: kTextTheme.headlineSmall)),
                      ),
                      const SizedBox(height: 20),
                      const Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              TransactionItem(
                                title: 'food',
                                date: '12/2/2025',
                                amount: '400',
                                isIncome: true,
                              ),
                              TransactionItem(
                                title: 'food',
                                date: '12/2/2025',
                                amount: '400',
                              ),
                              TransactionItem(
                                title: 'food',
                                date: '12/2/2025',
                                amount: '400',
                                isIncome: true,
                              ),
                              TransactionItem(
                                title: 'food',
                                date: '12/2/2025',
                                amount: '400',
                              ),
                              TransactionItem(
                                title: 'food',
                                date: '12/2/2025',
                                amount: '400',
                                isIncome: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
