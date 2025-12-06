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
                padding: paddingAllLarge,
                decoration: BoxDecoration(
                  color: brandGreen,
                  borderRadius: radiusMedium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    Text(
                      '\$7,783.00',
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(color: Colors.white),
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
              _buildTransactionItem(
                context,
                Icons.fastfood,
                'KFC',
                'June 5, 2024',
                '-\$15.00',
                Colors.red,
              ),
              _buildTransactionItem(
                context,
                Icons.shopping_bag,
                'Zara',
                'June 4, 2024',
                '-\$120.00',
                Colors.red,
              ),
              _buildTransactionItem(
                context,
                Icons.attach_money,
                'Salary',
                'June 1, 2024',
                '+\$3000.00',
                Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildTransactionItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String amount,
    Color amountColor,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: radiusMedium),
      child: ListTile(
        leading: Icon(icon, size: 30, color: brandGreen),
        title: Text(title, style: Theme.of(context).textTheme.titleLarge),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        trailing: Text(
          amount,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: amountColor),
        ),
      ),
    );
  }
}
