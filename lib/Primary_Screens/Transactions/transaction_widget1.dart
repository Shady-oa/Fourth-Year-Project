import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Widget transactionCell({
  required String name,
  required BuildContext context,
  required String description,
  required String type,
  required String amount,
  required Timestamp createdAt,
}) {
  Color typeColor;
  switch (type) {
    case "income":
      typeColor = accentColor;
      break;
    case "expense":
      typeColor = errorColor;
      break;
    case "saving":
      typeColor = brandGreen;
      break;
    default:
      typeColor = Theme.of(context).colorScheme.onSurface;
  }
  DateTime? dt = createdAt.toDate();

  String formattedDate = DateFormat('EEE, MMM d, yyyy – HH:mm').format(dt);

  return Container(
    margin: marginAllTiny,
    padding: paddingAllMedium,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: radiusMedium,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          blurRadius: 1,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // LEFT SIDE
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        // RIGHT SIDE
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
