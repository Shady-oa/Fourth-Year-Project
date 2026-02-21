import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

class StreakBanner extends StatelessWidget {
  final int streakCount;
  final String streakLevel;

  const StreakBanner({
    super.key,
    required this.streakCount,
    required this.streakLevel,
  });

  @override
  Widget build(BuildContext context) {
    const colors = {
      'Base': Color(0xFF6C757D),
      'Bronze': Color(0xFFCD7F32),
      'Silver': Color(0xFF9E9E9E),
      'Gold': Color(0xFFFFC107),
      'Platinum': Color(0xFF00BCD4),
      'Diamond': Color(0xFF7C4DFF),
    };
    const emojis = {
      'Base': '🔥',
      'Bronze': '🥉',
      'Silver': '🥈',
      'Gold': '🥇',
      'Platinum': '💎',
      'Diamond': '💠',
    };
    final color = colors[streakLevel] ?? brandGreen;
    final emoji = emojis[streakLevel] ?? '🔥';
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakCount Day${streakCount == 1 ? '' : 's'} Streak',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$streakLevel Saver',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (streakCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                streakCount > 99 ? '99+' : '$streakCount',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
