import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Budget extends StatefulWidget {
  const Budget({super.key});

  @override
  BudgetState createState() => BudgetState();
}

class BudgetState extends State<Budget> {
  // UI-only placeholder data
  List<Map<String, dynamic>> budgets = [
    {"id": "1", "category": "Food", "amount": 2000, "endDate": "2025-01-10"},
    {
      "id": "2",
      "category": "Transport",
      "amount": 800,
      "endDate": "2025-01-20",
    },
  ];

  double totalBudget = 2800; // static placeholder

  void addBudgetUIOnly() {
    // Shows UI only (no saving)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("Add New Budget"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(decoration: InputDecoration(labelText: "Category")),
            TextField(
              decoration: InputDecoration(labelText: "Budgeted Amount"),
            ),
            SizedBox(height: spacerMedium),
            Text("Select End Date (UI only)"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Add (UI Only)"),
          ),
        ],
      ),
    );
  }

  void openBudgetDetailsUIOnly() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BudgetDetailsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const CustomHeader(headerName: "Budgets"),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Budget",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  "\$$totalBudget",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),

            const SizedBox(height: spacerSmall),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                child: Padding(
                  padding: paddingAllMedium,
                  child: ListView.builder(
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      return GestureDetector(
                        onTap: openBudgetDetailsUIOnly,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: spacerMedium),
                          padding: paddingAllMedium,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha((255 * 0.8).round()),
                            borderRadius: radiusMedium,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget['category'],
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Amount: \$${budget['amount']}",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                    ),
                              ),
                              Text(
                                "End Date: ${budget['endDate']}",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface.withAlpha((255 * 0.7).round()),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 19),
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50.0,
                      vertical: spacerMedium,
                    ),
                  ),
                  onPressed: addBudgetUIOnly,
                  child: Text(
                    "Add Budget",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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

// -------------------------
//   Details Page (UI Only)
// -------------------------

class BudgetDetailsPage extends StatelessWidget {
  const BudgetDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> expenses = [
      {"description": "Lunch", "amount": 300, "date": "2025-01-01T12:30:00"},
      {"description": "Taxi", "amount": 150, "date": "2025-01-02T08:40:00"},
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(spacerMedium),
              child: Row(
                children: [
                  Text(
                    "Budget Details",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  const Icon(Icons.notifications_none),
                ],
              ),
            ),

            // Top area
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: spacerMedium,
                vertical: spacerSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text("Total Budget"),
                      Text(
                        "\$2000",
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text("Total Expense"),
                      Text(
                        "\$450",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                child: ListView.builder(
                  padding: paddingAllMedium,
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final date = DateTime.parse(expense['date']);
                    final formattedDate = DateFormat.yMMMd().format(date);
                    final formattedTime = DateFormat.Hm().format(date);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: spacerSmall),
                      padding: paddingAllMedium,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((255 * 0.8).round()),
                        borderRadius: radiusSmall,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense['description'],
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                ),
                                const SizedBox(height: spacerSmall),
                                Text(
                                  "$formattedDate  •  $formattedTime",
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface.withAlpha((255 * 0.7).round()),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "\$${expense['amount']}",
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surface.withAlpha((255 * 0.7).round()),
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: spacerSmall, bottom: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 12,
                  ),
                ),
                onPressed: () {},
                child: Text(
                  "Add Expense (UI Only)",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
