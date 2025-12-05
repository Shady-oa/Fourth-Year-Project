import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
            Text('Good Morning', style: Theme.of(context).textTheme.headlineSmall),
            Text('Alex', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        actions: [Padding(padding: paddingAllTiny, child: NotificationIcon())],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                        Text('Total Balance', style: Theme.of(context).textTheme.bodyMedium),
                        Text('\$7,783.00', style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total Expense', style: Theme.of(context).textTheme.bodyMedium),
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
                const SizedBox(height: 10),
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
                    const SizedBox(width: 10),
                    Text('\$20,000.00', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '30% Of Your Expenses, Looks Good.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
