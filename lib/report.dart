import 'package:final_project/constants.dart';
import 'package:flutter/material.dart';

class ReportPage extends StatelessWidget {
  final List<double> budgetSpendingData = [30, 20, 15, 25, 10];
  final List<double> savingGoalsData = [40, 30, 20, 10];
  final List<String> budgetCategories = [
    "Rent",
    "Food",
    "Transport",
    "Utilities",
    "Other",
  ];
  final List<String> savingGoals = ["Vacation", "Car", "Gadgets", "Emergency"];

  ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: kTextTheme.bodyMedium,
                        ),
                        Text(
                          '\$7,783.00',
                          style: kTextTheme.headlineMedium,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Expense',
                          style: kTextTheme.bodyMedium,
                        ),
                        Text(
                          '-\$1,187.40',
                          style: kTextTheme.headlineMedium
                              ?.copyWith(color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 0.3,
                        backgroundColor: primaryText.withOpacity(0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(brandGreen),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '\$20,000.00',
                      style: kTextTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '30% Of Your Expenses, Looks Good.',
                style: kTextTheme.bodyMedium,
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
                  child: const Column(
                    children: [
                      DefaultTabController(
                          length: 4,
                          child: TabBar(
                              tabs: [
                                Tab(text: 'Tab 1'),
                                Tab(text: 'Tab 2'),
                                Tab(text: 'Tab 3'),
                                Tab(text: 'Tab 4'),
                              ])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
