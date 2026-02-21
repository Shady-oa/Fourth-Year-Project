import 'package:flutter/material.dart';
import 'package:final_project/Constants/colors.dart';

/// A label/value row used inside the transaction confirmation sheet.
class ConfirmRow extends StatelessWidget {
  const ConfirmRow(
    this.label,
    this.value, {
    super.key,
    this.highlight = false,
  });

  final String label;
  final String value;

  /// When true, the value is rendered larger and in [errorColor].
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                fontSize: highlight ? 15 : 13,
                color: highlight ? errorColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
