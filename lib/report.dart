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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Spacer(),
                    Text(
                      'Quickly Analysis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xffF1FFF3),
                      ),
                    ),
                    Spacer(),
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: Color(0xffF1FFF3),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
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
                          style: TextStyle(
                            color: Color(0xffF1FFF3),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '\$7,783.00',
                          style: TextStyle(
                            color: Color(0xffF1FFF3),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Expense',
                          style: TextStyle(
                            color: Color(0xffF1FFF3),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '-\$1,187.40',
                          style: TextStyle(
                            color: Color(0xff3299FF),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
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
                        backgroundColor: Color(0xffF1FFF3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '\$20,000.00',
                      style: TextStyle(color: Color(0xffF1FFF3), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '30% Of Your Expenses, Looks Good.',
                style: TextStyle(color: Color(0xffF1FFF3), fontSize: 14),
              ),
              SizedBox(height: 40),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                    color: Color(0xFF093030),
                  ),
                  child: Column(
                    children: [
                      DefaultTabController(length:4, child: TabBar(tabs: [
                        
                      ])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Color(0xFF031314),
    );
  }
}
