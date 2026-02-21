import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Custom Date Row ──────────────────────────────────────────────────────────
class ReportCustomDateRow extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;

  const ReportCustomDateRow({
    super.key,
    required this.startDate,
    required this.endDate,
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
              final date = await showDatePicker(
                context: context,
                initialDate: startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) onStartDateChanged(date);
            },
            icon: const Icon(Icons.calendar_today, size: 15),
            label: Text(
              startDate == null
                  ? 'Start Date'
                  : DateFormat('dd MMM').format(startDate!),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: endDate ?? DateTime.now(),
                firstDate: startDate ?? DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) onEndDateChanged(date);
            },
            icon: const Icon(Icons.calendar_today, size: 15),
            label: Text(
              endDate == null
                  ? 'End Date'
                  : DateFormat('dd MMM').format(endDate!),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
