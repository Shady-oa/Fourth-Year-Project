import 'package:final_project/transaction.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(Hmp());
}

class Hmp extends StatelessWidget {
  const Hmp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF031314),
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
                          style: TextStyle(
                            color: Color(0xffF1FFF3),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Good Morning',
                          style: TextStyle(
                            color: Color(0xffF1FFF3),
                            fontSize: 16,
                          ),
                        ),
                      ],
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

                const SizedBox(height: 20),
                // Balance and Expense Section
                Row(
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
                const SizedBox(height: 10),
                Row(
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
                const SizedBox(height: 10),
                Text(
                  '30% Of Your Expenses, Looks Good.',
                  style: TextStyle(color: Color(0xffF1FFF3), fontSize: 14),
                ),
              ],
            ),
          ),
          // Rounded Container for Main Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF093030),
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
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          color: Color(0xFF00D09E),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.directions_car,
                                  color: Colors.black,
                                  //size: 40,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Savings On Goals',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Spacer(),
                      Container(
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          color: Color(0xFF00D09E),
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
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '\$4,000.00',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Food Last Week',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '-\$100.00',
                                  style: TextStyle(
                                    color: Color(0xff3299FF),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
                              color: Color(0xff0E3E3E),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: TabBar(
                                //isScrollable: true,
                                dividerColor: Colors.transparent,
                                labelStyle: TextStyle(color: Colors.black),
                                unselectedLabelColor: Color(0xffF1FFF3),
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Color(0xff00D09E),
                                ),
                                //labelColor: Colors.amber,
                                tabs: [
                                  Tab(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'Daily',
                                        style: TextStyle(
                                          //color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'Weekly',
                                        style: TextStyle(
                                          //color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Tab(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'Monthly',
                                        style: TextStyle(
                                          //color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Expanded(
                            child: TabBarView(
                              children: [
                                Transaction(),
                                Transaction(),
                                Transaction(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  /* Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TabButton(text: 'Daily'),
                      TabButton(text: 'Weekly'),
                      TabButton(text: 'Monthly', isSelected: true),
                    ],
                  ),*/
                  /* const SizedBox(height: 20),
                  // Transactions List
                  Expanded(
                    child: ListView(
                      children: [
                        TransactionItem(
                          icon: Icons.attach_money,
                          title: 'Salary',
                          date: 'April 30',
                          amount: '\$4,000.00',
                          isIncome: true,
                        ),
                        TransactionItem(
                          icon: Icons.shopping_cart,
                          title: 'Groceries',
                          date: 'April 24',
                          amount: '-\$100.00',
                        ),
                        TransactionItem(
                          icon: Icons.home,
                          title: 'Rent',
                          date: 'April 15',
                          amount: '-\$674.40',
                        ),
                      ],
                    ),
                  ),*/
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
            backgroundColor: isIncome ? Colors.blueAccent : Colors.greenAccent,
            child: Icon(icon, color: Colors.white),
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
