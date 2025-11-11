import 'package:flutter/material.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff052224),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                bottom: 50,
                right: 20,
              ),
              child: Row(
                children: [
                  const Text(
                    "Add Expense",
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

            //main content
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8.0), // Reduced padding for label
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xffD2EAD7),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText:
                                'April 30, 2024', // Placeholder inside the field
                            suffixIcon: Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Color(
                                0xffDFF7E2), // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(32), // Rounded corners
                            ),
                          ),
                          style: TextStyle(
                              color: Color(0xff163D3B),
                              fontWeight:
                                  FontWeight.w600), // Black and bold text
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8.0), // Reduced padding for label
                          child: Text(
                            'Category',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xffD2EAD7),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Select the category',
                            filled: true,
                            fillColor: Color(
                                0xffDFF7E2), // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(32), // Rounded corners
                            ),
                          ),
                          style: TextStyle(
                              color: Color(0xff163D3B),
                              fontWeight:
                                  FontWeight.w600), // Black and bold text
                        ),
                        SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8.0), // Reduced padding for label
                          child: Text(
                            'Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xffD2EAD7),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: '\$25.00',
                            filled: true,
                            fillColor: Color(
                                0xffDFF7E2), // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(32), // Rounded corners
                            ),
                          ),
                          style: TextStyle(
                              color: Color(0xff163D3B),
                              fontWeight:
                                  FontWeight.w600), // Black and bold text
                        ),
                        SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8.0), // Reduced padding for label
                          child: Text(
                            'Expense Title',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xffD2EAD7),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Dinner',
                            filled: true,
                            fillColor: Color(0xffD2EAD7),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(32), // Rounded corners
                            ),
                          ),
                          style: TextStyle(
                            color: Color(0xff163D3B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Write any additional notes here',
                            filled: true,
                            fillColor: Color(
                                0xffD2EAD7), // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12), // Rounded corners
                            ),
                          ),
                          style: TextStyle(
                            color: Color(0xff163D3B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 15),
                        Center(
                          child: SizedBox(
                            height: 36,
                            width: 169,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xff00D09E),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  color: Color(0xff093030),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
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
            )
          ],
        ),
      ),
     /* bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0E3E3E),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white70,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: SizedBox(width: 24, height: 24, child: Icon(Icons.home)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(width: 24, height: 24, child: Icon(Icons.pie_chart)),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon:
                SizedBox(width: 24, height: 24, child: Icon(Icons.swap_horiz)),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
                width: 24, height: 24, child: Icon(Icons.account_circle)),
            label: 'Profile',
          ),
        ],
      ),*/
    );
  }
}
