import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(MaterialApp(home: Balance(), debugShowCheckedModeBanner: false));
}

class Balance extends StatelessWidget {
  const Balance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: BalancePage());
  }
}

class BalancePage extends StatefulWidget {
  const BalancePage({super.key});

  @override
  _BalancePageState createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  // Variable to store the latest transaction amount
  double latestTransactionAmount = 4000.00;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF052224),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/svg/penny.svg',
                            height: 35,
                            width: 35,
                            color: Color(0xff00D09E),
                          ),
                          SizedBox(width: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Penny",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xff00D09E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Wise',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xff00D09E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Spacer(),
                      Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xffF1FFF3),
                        ),
                      ),
                      Spacer(),
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffDFF7E2),
                        ),
                        child: Icon(
                          Icons.notifications_none,
                          color: Color(0xff093030),
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
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '\$7,783.00',
                            style: TextStyle(
                              color: Colors.white,
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
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '-\$1,187.40',
                            style: TextStyle(
                              color: Colors.blue,
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
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.greenAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '\$20,000.00',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '30% Of Your Expenses, Looks Good.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Income & Expense Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Income Container - navigate to the Income page
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to the income page
                        Navigator.pushNamed(context, '/income');
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.arrow_upward, color: Colors.green),
                            SizedBox(height: 8),
                            Text(
                              "Income",
                              style: TextStyle(color: Colors.white70),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "\$${latestTransactionAmount.toStringAsFixed(2)}", // Dynamically display the latest transaction
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.blue),
                          SizedBox(height: 8),
                          Text(
                            "Expense",
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "\$1,187.40",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Main Content Container for Transactions
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF093030),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 38, right: 38, top: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transactions Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Transactions",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("See all", style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Transaction Items
                      Expanded(
                        child: ListView(
                          children: [
                            transactionItem(
                              "Salary",
                              "Gig",
                              "18:27 - April 30",
                              "\$4,000.00",
                              Colors.green,
                            ),
                            transactionItem(
                              "Groceries",
                              "Vegetables",
                              "17:00 - April 24",
                              "-\$100.00",
                              Colors.blue,
                            ),
                            transactionItem(
                              "Rent",
                              "Rent",
                              "8:30 - April 15",
                              "-\$674.40",
                              Colors.blue,
                            ),
                            transactionItem(
                              "Transport",
                              "Bus fee",
                              "9:30 - April 08",
                              "-\$4.13",
                              Colors.blue,
                            ),
                          ],
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

  // Function to update the latest transaction amount
  void updateTransactionAmount(double newAmount) {
    setState(() {
      latestTransactionAmount = newAmount;
    });
  }

  Widget transactionItem(
    String title,
    String description,
    String date,
    String amount,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 40),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
              Text(description, style: TextStyle(color: Colors.white70)),
              Text(date, style: TextStyle(color: Colors.white70)),
            ],
          ),
          Spacer(),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
