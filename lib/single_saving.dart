import 'package:flutter/material.dart';

class SingleSaving extends StatelessWidget {
  const SingleSaving({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff052224),
      body: SafeArea(
        child: Column(
          
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                bottom: 50,
                right: 20,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back, color: Color(0xffDFF7E2)),
                  ),
                  SizedBox(width: 5),
                  const Text(
                    "Travel",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xffDFF7E2),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 30,
                    width: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xffDFF7E2),
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: Color(0xff093030),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  color: Color(0xff093030),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 45,
                    left: 50,
                    right: 50,
                    bottom: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Section
                      SizedBox(
                        height: 160,
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  "Goal",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xffDFF7E2),
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "\$1,900.00",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xffDFF7E2),
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Amount Saved",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xffDFF7E2),
                                  ),
                                ),
                                Text(
                                  "\$654.00",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xffDFF7E2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xff6DB6FE),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.flight,
                                      color: Colors.white,
                                      size: 80,
                                    ),
                                    Text(
                                      "Travel",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Progress Bar Section
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xffDFF7E2),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(5),
                                ),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 0.2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xff00D09E),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "\$1,900.00",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: Color(0xffDFF7E2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(
                          "30% Of The Goal Saved",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: Color(0xffDFF7E2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "Transactions",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          color: Color(0xffD2EAD7),
                        ),
                      ),
                      // Scrollable List of Deposits

                      //main content
                      Expanded(
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            return depositList();
                          },
                        ),
                      ),
                    
                      // Fixed Add More Button
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          child: GestureDetector(
                            onTap: () {
                              addDialog(context);
                            },
                            child: Container(
                              height: 36,
                              width: 169,
                              decoration: const BoxDecoration(
                                color: Color(0xff00D09E),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "Add Savings",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff093030),
                                  ),
                                ),
                              ),
                            ),
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

  // Deposit List Item Widget
  static Widget depositList() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          Container(
            height: 53,
            width: 57,
            decoration: const BoxDecoration(
              color: Color(0xff6DB6FE),
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: const Icon(Icons.flight, size: 15),
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Travel Deposit",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Color(0xffDFF7E2),
                ),
              ),
              Row(
                children: [
                  Text(
                    "19:00",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff0068FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    " - ",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff0068FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "April 12",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xff0068FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          const Text(
            "\$217.00",
            style: TextStyle(
              fontSize: 15,
              color: Color(0xffDFF7E2),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void addDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Color(0xFF052224),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "New Category",
                  style: TextStyle(
                    color: Color(0xffDFF7E2),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Write...",
                    filled: true,
                    fillColor: Color(0xFFDFF7E2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: TextStyle(color: Color(0xFF093030)),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    // Save action
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00B686),
                    minimumSize: Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Save"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFDFF7E2),
                    minimumSize: Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Cancel"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
