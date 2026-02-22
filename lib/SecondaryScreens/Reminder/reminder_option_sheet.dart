// ─────────────────────────────────────────────────────────────────────────────
// SecondaryScreens/Reminders/reminder_options_sheet.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/SecondaryScreens/Reminder/reminder_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void showReminderOptionsSheet({
  required BuildContext context,
  required Reminder reminder,
  required VoidCallback onEdit,
  required VoidCallback onToggleActive,
  required VoidCallback onDelete,
}) {
  final dateFormat = DateFormat('dd MMM yyyy');
  final isDue =
      reminder.isActive && reminder.nextTriggerDate.isBefore(DateTime.now());
  final isActive = reminder.isActive;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ────────────────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Reminder name ─────────────────────────────────────────────
            Text(
              reminder.name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // ── Meta chips row ────────────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                // Active / Inactive badge
                _MetaChip(
                  icon: isActive
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_rounded,
                  label: isActive ? 'Active' : 'Inactive',
                  color: isActive ? brandGreen : Colors.grey.shade500,
                  bgColor: isActive
                      ? brandGreen.withOpacity(0.12)
                      : Colors.grey.shade200,
                ),
                // Frequency
                _MetaChip(
                  icon: Icons.repeat_rounded,
                  label: reminder.frequency.label,
                  color: accentColor,
                  bgColor: accentColor.withOpacity(0.10),
                ),
                // Trigger time
                _MetaChip(
                  icon: Icons.access_time_rounded,
                  label: reminder.triggerTimeLabel,
                  color: accentColor,
                  bgColor: accentColor.withOpacity(0.10),
                ),
                // Next trigger / due
                _MetaChip(
                  icon: Icons.schedule_rounded,
                  label: isDue
                      ? 'Due now!'
                      : dateFormat.format(reminder.nextTriggerDate),
                  color:
                      isDue ? Colors.orange.shade700 : Colors.grey.shade600,
                  bgColor: isDue
                      ? Colors.orange.withOpacity(0.10)
                      : Colors.grey.shade100,
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Edit ──────────────────────────────────────────────────────
            ListTile(
              leading: _IconBubble(
                icon: Icons.edit_outlined,
                color: accentColor,
              ),
              title: const Text(
                'Edit Reminder',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),

            // ── Activate / Deactivate ─────────────────────────────────────
            ListTile(
              leading: _IconBubble(
                icon: isActive
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                color: isActive ? Colors.orange.shade700 : brandGreen,
              ),
              title: Text(
                isActive ? 'Deactivate Reminder' : 'Activate Reminder',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.orange.shade700 : brandGreen,
                ),
              ),
              subtitle: Text(
                isActive
                    ? 'Pause — will not trigger until reactivated'
                    : 'Resume — will trigger on its schedule again',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onToggleActive();
              },
            ),

            // ── Delete ────────────────────────────────────────────────────
            ListTile(
              leading: _IconBubble(
                icon: Icons.delete_outline,
                color: errorColor,
              ),
              title: const Text(
                'Delete Reminder',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: errorColor,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBubble({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}