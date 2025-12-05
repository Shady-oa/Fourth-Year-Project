import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';

class AddExpense extends StatelessWidget {
  const AddExpense({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: spacerMedium,
                left: spacerMedium,
                bottom: 50.0, // Custom value
                right: spacerMedium,
              ),
              child: Row(
                children: [
                  Text(
                    "Add Expense",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  Container(
                    height: 30,
                    width: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    child: Icon(
                      Icons.notifications_none_outlined,
                      color: Theme.of(context).colorScheme.surface,
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
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50), // Custom value
                      topRight: Radius.circular(50), // Custom value
                    ),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 45, // Custom value
                      left: 50, // Custom value
                      right: 50, // Custom value
                      bottom: spacerSmall,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: spacerSmall), // Reduced padding for label
                          child: Text(
                            'Date',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.surface),
                          ),
                        ),
                        const SizedBox(
                          height: spacerTiny,
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText:
                                'April 30, 2024', // Placeholder inside the field
                            suffixIcon: const Icon(Icons.calendar_today),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface, // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  radiusMedium, // Rounded corners
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600), // Black and bold text
                        ),
                        const SizedBox(
                          height: spacerMedium,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: spacerSmall), // Reduced padding for label
                          child: Text(
                            'Category',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.surface),
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Select the category',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface, // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  radiusMedium, // Rounded corners
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600), // Black and bold text
                        ),
                        const SizedBox(height: spacerMedium),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: spacerSmall), // Reduced padding for label
                          child: Text(
                            'Amount',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.surface),
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: '\$25.00',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface, // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  radiusMedium, // Rounded corners
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600), // Black and bold text
                        ),
                        const SizedBox(height: spacerMedium),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: spacerSmall), // Reduced padding for label
                          child: Text(
                            'Expense Title',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Theme.of(context).colorScheme.surface),
                          ),
                        ),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Dinner',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius:
                                  radiusMedium, // Rounded corners
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: spacerMedium),
                        TextField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Write any additional notes here',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface, // White background inside the field
                            border: OutlineInputBorder(
                              borderRadius:
                                  radiusMedium, // Rounded corners
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: spacerMedium),
                        Center(
                          child: SizedBox(
                            height: 36, // Custom value
                            width: 169, // Custom value
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandGreen,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: spacerMedium, vertical: spacerSmall),
                              ),
                              child: Text(
                                'Save',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
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
