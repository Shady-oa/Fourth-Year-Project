import 'package:flutter/material.dart';

class SingleBudget extends StatelessWidget {
  const SingleBudget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff052224),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Center(
                        child: Text(
                          "Transport",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xffDFF7E2),
                          ),
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
                      )
                    ],
                  ),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Budget", style: TextStyle(color: Colors.white)),
                          SizedBox(height: 4),
                          Text(
                            "\$2,187.40",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: Color(0xffDFF7E2),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Expenses",
                              style: TextStyle(color: Colors.white)),
                          SizedBox(height: 4),
                          Text(
                            " \$1,783.00",
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
                  SizedBox(height: 22),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(0xffDFF7E2),
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xff00D09E),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "\$2,187.40",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: Color(0xffDFF7E2),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "18% Of Budget Used",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: Color(0xffDFF7E2),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Transactions",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            //main content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  color: Color(0xff093030),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 38,
                    right: 38,
                    top: 30,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            transactionItem("Transport", "Fuel",
                                "17:00 - Nov 18", "\$-500"),
                            transactionItem("Transport", "Car Parts",
                                "17:00 - Nov 10", "\$-700"),
                            transactionItem("Transport", "Tiers",
                                "17:00 - Nov 09", "\$-500"),
                            transactionItem("Transport", "Public Transport",
                                "17:00 - Nov 05", "\$-200"),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 36,
                          width: 169,
                          decoration: const BoxDecoration(
                            color: Color(0xff00D09E),
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                          child: const Center(
                            child: Text(
                              "Add Expense",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff093030),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  //expenses
  Widget transactionItem(
      String title, String description, String date, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.circle, color: Color(0xffF1FFF3), size: 40),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(color: Color(0xffF1FFF3), fontSize: 16)),
              Text(description,
                  style: TextStyle(
                    color: Color(0xffF1FFF3),
                    fontSize: 12,
                  )),
              Text(date, style: TextStyle(color: Color(0xff3299FF))),
            ],
          ),
          Spacer(),
          Text(
            amount,
            style: TextStyle(
              color: Color(0xffDFF7E2),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
