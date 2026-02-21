import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:final_project/Primary_Screens/Savings/savings_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class SavingCard extends StatelessWidget {
  final Saving saving;
  final VoidCallback onAddFunds;
  final VoidCallback onShowOptions;
  final VoidCallback onTap;

  const SavingCard({
    super.key,
    required this.saving,
    required this.onAddFunds,
    required this.onShowOptions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysLeft = saving.deadline.difference(DateTime.now()).inDays;
    final overdue = daysLeft < 0;
    final urgent = !overdue && daysLeft <= 7;
    final pct = saving.progressPercent;

    Color statusColor;
    if (saving.achieved) {
      statusColor = brandGreen;
    } else if (overdue) {
      statusColor = errorColor;
    } else if (urgent) {
      statusColor = Colors.orange;
    } else {
      statusColor = accentColor;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: saving.achieved
                ? brandGreen.withOpacity(0.45)
                : overdue
                ? errorColor.withOpacity(0.35)
                : Colors.grey.shade200,
            width: saving.achieved ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.savings, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                saving.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (saving.achieved)
                              _statusBadge('✓ Achieved', brandGreen)
                            else if (overdue)
                              _statusBadge('Overdue', errorColor)
                            else if (urgent)
                              _statusBadge('Due soon', Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: statusColor.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(saving.deadline),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                saving.achieved
                                    ? 'Goal met!'
                                    : overdue
                                    ? '${daysLeft.abs()}d overdue'
                                    : '$daysLeft days left',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: onShowOptions,
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}% saved',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        '${SavingsFmt.ksh(saving.balance)} left',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _amountBlock(
                      label: 'Saved',
                      amount: saving.savedAmount,
                      color: brandGreen,
                      theme: theme,
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  Expanded(
                    child: _amountBlock(
                      label: 'Target',
                      amount: saving.targetAmount,
                      color: Colors.grey.shade700,
                      theme: theme,
                      alignRight: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (!saving.achieved)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAddFunds,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text(
                      'Add Fund',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: brandGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.celebration_outlined,
                        size: 16,
                        color: brandGreen,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Goal achieved! Great work 🎉',
                        style: TextStyle(
                          fontSize: 13,
                          color: brandGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _amountBlock({
    required String label,
    required double amount,
    required Color color,
    required ThemeData theme,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: alignRight ? 0 : 12,
            right: alignRight ? 12 : 0,
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ),
        const SizedBox(height: 3),
        Padding(
          padding: EdgeInsets.only(
            left: alignRight ? 0 : 12,
            right: alignRight ? 12 : 0,
          ),
          child: Text(
            SavingsFmt.ksh(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
