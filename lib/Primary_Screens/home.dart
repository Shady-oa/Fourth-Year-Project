import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:final_project/Primary_Screens/notifications.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, Welcome Back',
                          style: kTextTheme.headlineSmall,
                        ),

                        Text('Good Morning', style: kTextTheme.bodyLarge),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.circle_notifications_rounded,
                        size: 30,
                        color: primaryText,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const Notifications(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                // Balance and Expense Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Balance', style: kTextTheme.bodyMedium),
                        Text('\$7,783.00', style: kTextTheme.headlineMedium),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total Expense', style: kTextTheme.bodyMedium),
                        Text(
                          '-\$1,187.40',
                          style: kTextTheme.headlineMedium?.copyWith(
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 0.3,
                        backgroundColor: primaryText.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          brandGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('\$20,000.00', style: kTextTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '30% Of Your Expenses, Looks Good.',
                  style: kTextTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Rounded Container for Main Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: primaryText,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Savings Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 130,
                        // width: MediaQuery.of(context).size.width*0.4,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          color: brandGreen,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.directions_car,
                                  color: primaryText,
                                  //size: 40,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Savings On Goals',
                                  style: kTextTheme.bodyMedium?.copyWith(
                                    color: primaryText,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 130,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          color: brandGreen,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  'Revenue Last Week',
                                  style: kTextTheme.bodyMedium?.copyWith(
                                    color: primaryText,
                                  ),
                                ),
                                Text(
                                  '\$4,000.00',
                                  style: kTextTheme.bodyLarge?.copyWith(
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Food Last Week',
                                  style: kTextTheme.bodyMedium?.copyWith(
                                    color: primaryText,
                                  ),
                                ),
                                Text(
                                  '-\$100.00',
                                  style: kTextTheme.bodyLarge?.copyWith(
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tabs (Daily, Weekly, Monthly)
                  Expanded(
                    child: DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: primaryText.withOpacity(0.8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: TabBar(
                                //isScrollable: true,
                                dividerColor: Colors.transparent,
                                labelStyle: kTextTheme.bodyMedium?.copyWith(
                                  color: primaryText,
                                ),
                                unselectedLabelColor: primaryBg,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: brandGreen,
                                ),
                                //labelColor: Colors.amber,
                                tabs: const [
                                  Tab(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 8,
                                      ),
                                      child: Text('Daily'),
                                    ),
                                  ),
                                  Tab(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      child: Text('Weekly'),
                                    ),
                                  ),
                                  Tab(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      child: Text('Monthly'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Transaction Item Widget
class TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final String amount;
  final bool isIncome;

  const TransactionItem({
    super.key,
    required this.icon,
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
            child: Icon(icon, color: primaryText),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: kTextTheme.bodyLarge?.copyWith(color: primaryBg),
              ),
              Text(
                date,
                style: kTextTheme.bodySmall?.copyWith(
                  color: primaryBg.withOpacity(0.7),
                ),
              ),
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
