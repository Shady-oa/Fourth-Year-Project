import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:final_project/Primary_Screens/Savings/savings_helpers.dart';
import 'package:flutter/material.dart';


class SavingsSummaryBox extends StatelessWidget {
  final Saving saving;

  const SavingsSummaryBox({super.key, required this.saving});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brandGreen.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _sumRow('Saved', SavingsFmt.ksh(saving.savedAmount)),
          const SizedBox(height: 4),
          _sumRow('Target', SavingsFmt.ksh(saving.targetAmount)),
          const SizedBox(height: 4),
          _sumRow(
            'Remaining',
            SavingsFmt.ksh(saving.balance),
            valueColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _sumRow(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: valueColor,
        ),
      ),
    ],
  );
}
