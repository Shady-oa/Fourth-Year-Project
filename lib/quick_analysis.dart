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
      backgroundColor: Color(0xFF031314),
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
                    child: Icon(Icons.arrow_back, color: Color(0xffF1FFF3)),
                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: Color(0xffF1FFF3),
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Savings On Goals',
                        style: TextStyle(
                          color: Color(0xffF1FFF3),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'Revenue Last Week',
                        style: TextStyle(
                          color: Color(0xff00D09E),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '\$4,000.00',
                        style: TextStyle(
                          color: Color(0xffF1FFF3),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        'Food Last Week',
                        style: TextStyle(
                          color: Color(0xff00D09E),
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
                ],
              ),
            ),
            SizedBox(height: 40),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  color: Color(0xff093030),
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
                          color: Color(0xffF1FFF3),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(child: Text('Graph')),
                      ),
                      SizedBox(height: 20),
                      Expanded(
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
                              TransactionItem(
                                title: 'food',
                                date: '12/2/2025',
                                amount: '400',
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
