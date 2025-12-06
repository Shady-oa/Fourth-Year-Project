import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 1. IMPORT the intl package

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  final double income = 15000.0;
  final double expenses = 4780.0;

  // 2. Define a NumberFormat instance for comma separation and 2 decimal places
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the balance
    final double balance = income - expenses;

    // Format the values
    final String formattedBalance = _formatCurrency(balance);
    final String formattedIncome = _formatCurrency(income);
    final String formattedExpenses = _formatCurrency(expenses);

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
            Text(
              'Good Morning',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('Alex', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        actions: [Padding(padding: paddingAllTiny, child: NotificationIcon())],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: paddingAllMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Section
              Container(
                width: double.infinity,
                padding: paddingAllMedium,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface,
                  borderRadius: radiusMedium,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.7),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    // 3. Display formatted balance
                    Text(
                      'Ksh $formattedBalance',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                    ),
                    sizedBoxHeightLarge,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_circle_up_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(.6),
                              size: 40,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Income',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                ),
                                // 4. Display formatted income
                                Text(
                                  'Ksh $formattedIncome',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        sizedBoxWidthLarge,
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_circle_down_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(.6),
                              size: 40,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expenses',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                ),
                                // 5. Display formatted expenses
                                Text(
                                  'Ksh $formattedExpenses',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              sizedBoxHeightLarge,
              // Quick Actions Section
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              sizedBoxHeightSmall,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickActionCard(context, Icons.add, 'Add Expense'),
                  _buildQuickActionCard(context, Icons.savings, 'Savings'),
                  _buildQuickActionCard(
                    context,
                    Icons.receipt_long,
                    'Transactions',
                  ),
                  _buildQuickActionCard(context, Icons.chat, 'AI Assistant'),
                ],
              ),
              sizedBoxHeightLarge,
              // Recent Transactions Section
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              sizedBoxHeightSmall,
              // NOTE: The transaction items below now use the formatting function as well
              _buildTransactionItem(
                context,
                Icons.fastfood,
                'KFC',
                'June 5, 2024',
                -15.00, // Pass as number
                Colors.red,
                currencySymbol: '\$',
              ),
              _buildTransactionItem(
                context,
                Icons.shopping_bag,
                'Zara',
                'June 4, 2024',
                -120.00, // Pass as number
                Colors.red,
                currencySymbol: '\$',
              ),
              _buildTransactionItem(
                context,
                Icons.attach_money,
                'Salary',
                'June 1, 2024',
                3000.00, // Pass as number
                Colors.green,
                currencySymbol: '\$',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Utility function updated to format the number
  Widget _buildTransactionItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    double amount, // Changed to double
    Color amountColor, {
    String currencySymbol = 'Ksh ', // Added currency symbol parameter
  }) {
    // Determine sign and format the number with commas
    final String sign = amount < 0 ? '-' : '+';
    final String formattedAmount = _formatCurrency(
      amount.abs(),
    ); // Format the absolute value

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: radiusMedium),
      child: ListTile(
        leading: Icon(icon, size: 30, color: brandGreen),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        trailing: Text(
          '$sign$currencySymbol$formattedAmount', // Combine sign, symbol, and formatted amount
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: amountColor),
        ),
      ),
    );
  }

  // The Quick Action Card function remains the same
  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    return Column(
      children: [
        Container(
          padding: paddingAllMedium,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            borderRadius: radiusMedium,
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Icon(icon, size: 30, color: brandGreen),
        ),
        sizedBoxHeightSmall,
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
