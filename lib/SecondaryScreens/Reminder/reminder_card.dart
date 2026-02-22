// ─────────────────────────────────────────────────────────────────────────────
// SecondaryScreens/Reminders/reminder_card.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/SecondaryScreens/Reminder/reminder_model.dart';
import 'package:final_project/SecondaryScreens/Reminder/reminder_option_sheet.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  void _openOptions(BuildContext context) {
    showReminderOptionsSheet(
      context: context,
      reminder: reminder,
      onEdit: onEdit,
      onToggleActive: onToggleActive,
      onDelete: onDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');
    final isActive = reminder.isActive;
    final isDue =
        isActive && reminder.nextTriggerDate.isBefore(DateTime.now());

    final iconBg = !isActive
        ? Colors.grey.shade100
        : isDue
            ? Colors.orange.withOpacity(0.12)
            : accentColor.withOpacity(0.10);

    final iconColor = !isActive
        ? Colors.grey.shade400
        : isDue
            ? Colors.orange.shade700
            : accentColor;

    final borderColor = !isActive
        ? Colors.grey.shade200
        : isDue
            ? Colors.orange.shade300
            : theme.colorScheme.onSurface.withAlpha(20);

    final borderWidth = (!isActive || isDue) ? 1.5 : 1.0;

    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            const SizedBox(height: 3),
            Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: GestureDetector(
        onTap: () => _openOptions(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: !isActive
                ? Color.alphaBlend(
                    Colors.grey.withOpacity(0.04),
                    theme.colorScheme.surface,
                  )
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isActive ? 0.04 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon bubble ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    !isActive
                        ? Icons.alarm_off_rounded
                        : isDue
                            ? Icons.notifications_active_rounded
                            : Icons.alarm_rounded,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // ── Text body ───────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + badges row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              reminder.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: !isActive
                                    ? theme.colorScheme.onSurface
                                        .withAlpha(120)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusBadge(isActive: isActive),
                          const SizedBox(width: 6),
                          // Frequency pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: !isActive
                                  ? Colors.grey.withOpacity(0.10)
                                  : accentColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              reminder.frequency.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: !isActive
                                    ? Colors.grey.shade400
                                    : accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (reminder.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reminder.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withAlpha(isActive ? 120 : 80),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // ── Schedule row (date · time) ────────────────────
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: !isActive
                                ? Colors.grey.shade300
                                : isDue
                                    ? Colors.orange.shade600
                                    : theme.colorScheme.onSurface
                                        .withAlpha(100),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _scheduleLabel(dateFormat, isActive, isDue),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: !isActive
                                    ? Colors.grey.shade400
                                    : isDue
                                        ? Colors.orange.shade700
                                        : theme.colorScheme.onSurface
                                            .withAlpha(100),
                              ),
                            ),
                          ),
                          // Trigger-time chip
                          if (!isDue)
                            _TimeChip(
                              label: reminder.triggerTimeLabel,
                              isActive: isActive,
                            ),
                        ],
                      ),

                      // Tap hint
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'tap to manage',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _scheduleLabel(
      DateFormat fmt, bool isActive, bool isDue) {
    if (!isActive) {
      return 'Paused · ${fmt.format(reminder.nextTriggerDate)}';
    }
    if (isDue) return 'Due now!';
    return 'Next: ${fmt.format(reminder.nextTriggerDate)}';
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? brandGreen.withOpacity(0.12)
            : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.check_circle_rounded
                : Icons.pause_circle_rounded,
            size: 10,
            color: isActive ? brandGreen : Colors.grey.shade500,
          ),
          const SizedBox(width: 3),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isActive ? brandGreen : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time chip ─────────────────────────────────────────────────────────────────

class _TimeChip extends StatelessWidget {
  final String label;
  final bool isActive;
  const _TimeChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? accentColor.withOpacity(0.08)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 10,
            color: isActive ? accentColor : Colors.grey.shade400,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? accentColor : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}