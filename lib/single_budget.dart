import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';

class SingleBudget extends StatefulWidget {
  const SingleBudget({super.key});

  @override
  State<SingleBudget> createState() => _SingleBudgetState();
}

class _SingleBudgetState extends State<SingleBudget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
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
                          Icons.notifications_none,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Budget", style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text("\$2,187.40", style: Theme.of(context).textTheme.headlineMedium),
                        ],
                      ),
                      Container(height: 50, width: 1, color: Theme.of(context).colorScheme.onSurface),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Expenses", style: Theme.of(context).textTheme.bodyLarge),
                          const SizedBox(height: 4),
                          Text(
                            " \$1,783.00",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(5),
                            ),
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
                      Text("\$2,187.40", style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "18% Of Budget Used",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Transactions", style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),

            //main content
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
                  padding: const EdgeInsets.only(left: 38, right: 38, top: 30),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            transactionItem(
                              "Transport",
                              "Fuel",
                              "17:00 - Nov 18",
                              "\$-500",
                            ),
                            transactionItem(
                              "Transport",
                              "Car Parts",
                              "17:00 - Nov 10",
                              "\$-700",
                            ),
                            transactionItem(
                              "Transport",
                              "Tiers",
                              "17:00 - Nov 09",
                              "\$-500",
                            ),
                            transactionItem(
                              "Transport",
                              "Public Transport",
                              "17:00 - Nov 05",
                              "\$-200",
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 36,
                          width: 169,
                          decoration: const BoxDecoration(
                            color: brandGreen,
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                          child: Center(
                            child: Text(
                              "Add Expense",
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  //expenses
  Widget transactionItem(
    String title,
    String description,
    String date,
    String amount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.circle, color: Theme.of(context).colorScheme.surface, size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.surface),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ),
              ),
              Text(
                date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue),
              ),
            ],
          ),
          const Spacer(),
          Text(amount, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.surface)),
        ],
      ),
    );
  }
}
