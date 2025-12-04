import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:final_project/single_budget.dart';
import 'package:flutter/material.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  // List of categories
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.directions_car, 'label': 'Transport'},
    {'icon': Icons.medical_services, 'label': 'Medicine'},
    {'icon': Icons.local_grocery_store, 'label': 'Groceries'},
    {'icon': Icons.flight, 'label': 'Travel'},
    {'icon': Icons.school, 'label': 'Education'},
    {'icon': Icons.home, 'label': 'Rent'},
  ];

  // Function to add a new category
  void _addCategory(String label) {
    setState(() {
      _categories.add({'icon': Icons.category, 'label': label});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBg,
        title: CustomHeader(headerName: "Savings"),
      ),
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Balance", style: kTextTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text("\$1,187.40", style: kTextTheme.headlineMedium),
                        ],
                      ),
                      Container(height: 50, width: 1, color: primaryText),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total Target", style: kTextTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text(
                            "\$7,783.00",
                            style: kTextTheme.headlineMedium?.copyWith(
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: primaryText.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: brandGreen,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text("\$7,783.00", style: kTextTheme.bodyMedium),
                    ],
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "18% of savings saved",
                        style: kTextTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SingleBudget()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: primaryText,
                      shape: RoundedRectangleBorder(borderRadius: radiusSmall),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      'Savings Analysis',
                      style: kTextTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
