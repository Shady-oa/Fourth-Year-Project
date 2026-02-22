import 'package:final_project/Components/form_logo.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'About Penny Wise',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: paddingAllMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Center(child: formLogo),
            sizedBoxHeightXLarge,

            // Introduction Statement
            Text(
              'What is Penny Wise?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            sizedBoxHeightSmall,
            Text(
              "Penny Wise is a modern and intuitive personal finance management application designed to help you regain control over your money. Built with simplicity, automation, and intelligent insights in mind, it's more than just an expense tracker—it's your personalized roadmap to financial freedom.",
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
            sizedBoxHeightXLarge,

            Text(
              'How It Helps You',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            sizedBoxHeightMedium,

            // Feature Cards
            _FeatureCard(
              icon: Icons.auto_awesome,
              title: 'Penny AI',
              description:
                  'Ask questions about your spending, get customized financial advice, and view context-aware summaries of your habits powered by advanced AI.',
              isDark: isDark,
            ),
            _FeatureCard(
              icon: Icons.receipt_long_outlined,
              title: 'Intelligent Budgeting',
              description:
                  'Set realistic spending limits across different categories. Penny Wise tracks your progress and warns you before you overspend.',
              isDark: isDark,
            ),
            _FeatureCard(
              icon: Icons.savings_rounded,
              title: 'Goal-Oriented Savings',
              description:
                  'Create dedicated savings goals for emergencies, vacations, or big purchases. Visualize your progress securely and build a saving habit.',
              isDark: isDark,
            ),
            _FeatureCard(
              icon: Icons.insert_chart_rounded,
              title: 'Comprehensive Analytics',
              description:
                  'Generate detailed PDF reports, view beautiful category breakdowns, and compare your historical data to stay on top of your financial health.',
              isDark: isDark,
            ),
            _FeatureCard(
              icon: Icons.notifications_active_rounded,
              title: 'Smart Reminders',
              description:
                  'Never miss a bill or subscription payment. Schedule actionable alerts to keep your cash flow predictable and safe.',
              isDark: isDark,
            ),

            sizedBoxHeightXLarge,

            // Footer
            Center(
              child: Text(
                'Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: paddingAllMedium,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: radiusLarge,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: brandGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: brandGreen, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
