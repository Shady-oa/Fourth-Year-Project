import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
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
        backgroundColor: primaryBg,
        title: CustomHeader(headerName: "Transactions"),
      ),
      backgroundColor: primaryBg,
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
                            style: kTextTheme.bodyMedium?.copyWith(
                              color: primaryText.withOpacity(0.7),
                            ),
                          ),
                          Text('\$7,783.00', style: kTextTheme.headlineMedium),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Expense',
                            style: kTextTheme.bodyMedium?.copyWith(
                              color: primaryText.withOpacity(0.7),
                            ),
                          ),
                          Text(
                            '-\$1,187.40',
                            style: kTextTheme.headlineMedium?.copyWith(
                              color: Colors.blue,
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
                          backgroundColor: primaryText.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            brandGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: spacerSmall),
                      Text('\$20,000.00', style: kTextTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: spacerSmall),
                  Text(
                    '30% Of Your Expenses, Looks Good.',
                    style: kTextTheme.bodyMedium?.copyWith(
                      color: primaryText.withOpacity(0.7),
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
                          color: primaryText.withOpacity(0.1),
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
                              style: kTextTheme.bodyMedium?.copyWith(
                                color: primaryText.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: spacerTiny),
                            Text(
                              "\$${latestTransactionAmount.toStringAsFixed(2)}", // Dynamically display the latest transaction
                              style: kTextTheme.titleLarge,
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
                          color: primaryText.withOpacity(0.1),
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
                              style: kTextTheme.bodyMedium?.copyWith(
                                color: primaryText.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: spacerTiny),
                            Text("\$1,187.40", style: kTextTheme.titleLarge),
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
