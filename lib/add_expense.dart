import 'package:final_project/constants.dart';
import 'package:flutter/material.dart';

class AddExpenseScreen extends StatelessWidget {
  const AddExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
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
                  Text(
                    "Add Expense",
                    style: kTextTheme.headlineSmall,
                  ),
                  const Spacer(),
                  Container(
                    height: 30,
                    width: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryText,
                    ),
                    child: const Icon(
                      Icons.notifications_none_outlined,
                      color: primaryBg,
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
                    color: primaryText,
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
                            style: kTextTheme.bodyMedium
                                ?.copyWith(color: primaryBg),
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText:
                                'April 30, 2024', // Placeholder inside the field
                            suffixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: primaryBg, // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(32), // Rounded corners
                            ),
                          ),
                          style: kTextTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600), // Black and bold text
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8.0), // Reduced padding for label
                          child: Text(
                            'Category',
                            style: kTextTheme.bodyMedium
                                ?.copyWith(color: primaryBg),
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Select the category',
                            filled: true,
                            fillColor: primaryBg, // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(32), // Rounded corners
                            ),
                          ),
                          style: kTextTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600), // Black and bold text
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8.0), // Reduced padding for label
                          child: Text(
                            'Amount',
                            style: kTextTheme.bodyMedium
                                ?.copyWith(color: primaryBg),
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: '\$25.00',
                            filled: true,
                            fillColor: primaryBg, // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(32), // Rounded corners
                            ),
                          ),
                          style: kTextTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600), // Black and bold text
                        ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 8.0), // Reduced padding for label
                          child: Text(
                            'Expense Title',
                            style: kTextTheme.bodyMedium
                                ?.copyWith(color: primaryBg),
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Dinner',
                            filled: true,
                            fillColor: primaryBg,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(32), // Rounded corners
                            ),
                          ),
                          style: kTextTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Write any additional notes here',
                            filled: true,
                            fillColor: primaryBg, // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12), // Rounded corners
                            ),
                          ),
                          style: kTextTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: SizedBox(
                            height: 36,
                            width: 169,
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandGreen,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              child: Text(
                                'Save',
                                style: kTextTheme.bodyMedium?.copyWith(
                                    color: primaryText,
                                    fontWeight: FontWeight.w600),
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
    );
  }
}
