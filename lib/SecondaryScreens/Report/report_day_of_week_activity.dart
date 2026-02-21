import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

import 'report_card.dart';

// ─── Day of Week Activity ─────────────────────────────────────────────────────
class ReportDayOfWeekActivity extends StatelessWidget {
  final List<int> txByDayOfWeek;

  const ReportDayOfWeekActivity({super.key, required this.txByDayOfWeek});

  @override
  Widget build(BuildContext context) {
    final counts = txByDayOfWeek;
    final maxCount = counts.fold(0, (a, b) => a > b ? a : b);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return ReportCard(
      title: 'Activity by Day of Week',
      icon: Icons.calendar_view_week,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final ratio = maxCount > 0 ? counts[i] / maxCount : 0.0;
          final isMax = counts[i] == maxCount && maxCount > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  if (isMax)
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('🔥', style: TextStyle(fontSize: 8)),
                    ),
                  Text(
                    '${counts[i]}',
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: 70 * ratio + 4,
                    decoration: BoxDecoration(
                      color: isMax ? accentColor : accentColor.withOpacity(0.4),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[i],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
