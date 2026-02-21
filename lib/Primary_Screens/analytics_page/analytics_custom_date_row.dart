import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnalyticsCustomDateRow extends StatelessWidget {
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;

  const AnalyticsCustomDateRow({
    super.key,
    required this.customStartDate,
    required this.customEndDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: customStartDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) onStartDateChanged(d);
            },
            icon: const Icon(Icons.calendar_today, size: 15),
            label: Text(
              customStartDate == null
                  ? 'Start Date'
                  : DateFormat('dd MMM').format(customStartDate!),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: customEndDate ?? DateTime.now(),
                firstDate: customStartDate ?? DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) onEndDateChanged(d);
            },
            icon: const Icon(Icons.calendar_today, size: 15),
            label: Text(
              customEndDate == null
                  ? 'End Date'
                  : DateFormat('dd MMM').format(customEndDate!),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
