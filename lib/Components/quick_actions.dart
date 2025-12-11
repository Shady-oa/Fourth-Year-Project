// lib/Components/quick_action_card.dart

import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round()),
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
