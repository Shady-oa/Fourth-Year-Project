import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Components/them_toggle.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Statistics/statistics.dart';
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
        actions: [
          Padding(
            padding: paddingAllTiny,
            child: Row(children: [ThemeToggleIcon(), NotificationIcon()]),
          ),
        ],
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
                      ).colorScheme.onSurface.withOpacity(.4),
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
                      Statistics.totalBalance(),
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
                                  Statistics.totalIncome(),
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
                                  Statistics.totalExpense(),
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
                style: Theme.of(context).textTheme.titleLarge,
              ),
              sizedBoxHeightSmall,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickActionCard(
                    context,
                    Icons.account_balance_wallet_outlined,
                    'Add Income',
                    () {
                      // Handle Add Income action
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    Icons.add_card_outlined,
                    'Add Expense',
                    () {
                      // Handle Add Expense action
                    },
                  ),

                  _buildQuickActionCard(
                    context,
                    Icons.calculate_outlined,
                    'Set Budget',
                    () {
                      // Handle Set Budget action
                    },
                  ),
                  _buildQuickActionCard(
                    context,
                    Icons.analytics_outlined,
                    'Report',
                    () {
                      // Handle Add Saving action
                    },
                  ),
                ],
              ),
              sizedBoxHeightLarge,
              // Recent Transactions Section
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The Quick Action Card function remains the same
  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: paddingAllMedium,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: radiusMedium,
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          sizedBoxHeightSmall,
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
