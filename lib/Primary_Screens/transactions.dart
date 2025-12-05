import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/SecondaryScreens/expenses.dart';
import 'package:final_project/SecondaryScreens/income.dart';
import 'package:flutter/material.dart';

class Transactions extends StatefulWidget {
  const Transactions({super.key});

  @override
  _TransactionsState createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  // Variable to store the latest transaction amount
  double latestTransactionAmount = 4000.00;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: CustomHeader(headerName: "Transactions"),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: paddingAllMedium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Balance and Expense Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Balance',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text('\$7,783.00', style: Theme.of(context).textTheme.headlineMedium),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Expense',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            '-\$1,187.40',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: spacerSmall),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: 0.3,
                          backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            brandGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: spacerSmall),
                      Text('\$20,000.00', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: spacerSmall),
                  Text(
                    '30% Of Your Expenses, Looks Good.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Income & Expense Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacerMedium),
              child: Row(
                children: [
                  // Income Container - navigate to the Income page
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to the income page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Income()),
                        );
                      },
                      child: Container(
                        padding: paddingAllMedium,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: radiusMedium,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.arrow_circle_down_rounded,
                              color: brandGreen,
                            ),
                            const SizedBox(height: spacerSmall),
                            Text(
                              "Income",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: spacerTiny),
                            Text(
                              "\$${latestTransactionAmount.toStringAsFixed(2)}", // Dynamically display the latest transaction
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: spacerMedium),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to the income page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Expenses()),
                        );
                      },
                      child: Container(
                        padding: paddingAllMedium,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: radiusMedium,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.arrow_circle_up_rounded,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: spacerSmall),
                            Text(
                              "Expense",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: spacerTiny),
                            Text("\$1,187.40", style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
