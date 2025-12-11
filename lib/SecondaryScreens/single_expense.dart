import 'package:final_project/Components/back_button.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

class TravelSavingsPage extends StatelessWidget {
  const TravelSavingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomBackButton(),

                  Text(
                    "Travel",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Goal and Amount Saved
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Goal",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$1,962.93",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Amount Saved",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$653.31",
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(color: brandGreen),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((255 * 0.2).round()),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.4, // 40% progress
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
                  Text(
                    "\$1,962.93",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "30% Of Your Expenses, Looks Good.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                ),
              ),
              const SizedBox(height: 20),

              // Transaction List
              Text("April", style: Theme.of(context).textTheme.titleLarge),
              Expanded(
                child: ListView(
                  children: [
                    transactionItem(
                      "Travel Deposit",
                      "19:56 - April 30",
                      "\$217.77",
                    ),
                    transactionItem(
                      "Travel Deposit",
                      "17:42 - April 14",
                      "\$217.77",
                    ),
                    transactionItem(
                      "Travel Deposit",
                      "12:30 - April 02",
                      "\$217.77",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Add Savings Button
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    "Add Savings",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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

  Widget transactionItem(String title, String date, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Builder(
        builder: (context) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.flight, color: Colors.blue, size: 40),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.bodyLarge),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha((255 * 0.7).round()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(amount, style: Theme.of(context).textTheme.bodyLarge),
            ],
          );
        },
      ),
    );
  }
}