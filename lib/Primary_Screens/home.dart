import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBg,
        elevation: 0,
        leading: Padding(
          padding: paddingAllTiny,
          child: CircleAvatar(
            radius: 24,
            backgroundImage: const AssetImage("assets/image/icon 2.png"),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Morning', style: kTextTheme.headlineSmall),
            Text('Alex', style: kTextTheme.bodyLarge),
          ],
        ),
        actions: [Padding(padding: paddingAllTiny, child: NotificationIcon())],
      ),
      backgroundColor: primaryBg,
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
                        Text('Total Balance', style: kTextTheme.bodyMedium),
                        Text('\$7,783.00', style: kTextTheme.headlineMedium),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total Expense', style: kTextTheme.bodyMedium),
                        Text(
                          '-\$1,187.40',
                          style: kTextTheme.headlineMedium?.copyWith(
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
                    const SizedBox(width: 10),
                    Text('\$20,000.00', style: kTextTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '30% Of Your Expenses, Looks Good.',
                  style: kTextTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
