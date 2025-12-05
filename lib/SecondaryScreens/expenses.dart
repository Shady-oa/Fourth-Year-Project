import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Components/back_button.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/SecondaryScreens/add_expense.dart';
import 'package:final_project/SecondaryScreens/single_expense.dart';
import 'package:flutter/material.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: const CustomBackButton(),
        title: CustomHeader(headerName: "Expenses"),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Balance",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$7,783.00",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Expense",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "-\$1,187.40",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Savings Goals Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TravelSavingsPage(),
                          ),
                        );
                      },
                      child: savingsGoalItem("Travel", Icons.flight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Add More Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddExpense()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: radiusSmall),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    'Add More',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget savingsGoalItem(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 40),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
