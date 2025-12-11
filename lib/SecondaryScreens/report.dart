import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

class Report extends StatelessWidget {
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

  Report({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: Theme.of(context).colorScheme.onSurface,
                      child: Icon(
                        Icons.notifications_outlined,
                        color: Theme.of(context).colorScheme.surface,
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
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '\$7,783.00',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Expense',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '-\$1,187.40',
                          style: Theme.of(context).textTheme.headlineMedium
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
                        backgroundColor: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.2).round()),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(brandGreen),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '\$20,000.00',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '30% Of Your Expenses, Looks Good.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                    color: Theme.of(context).colorScheme.onSurface,
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
