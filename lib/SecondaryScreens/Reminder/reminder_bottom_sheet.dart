// ─────────────────────────────────────────────────────────────────────────────
// SecondaryScreens/Reminders/reminder_bottom_sheet.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/SecondaryScreens/Reminder/reminder_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Shows the Add/Edit reminder bottom sheet.
/// [existing] — pass a [Reminder] to pre-fill the form for editing.
/// [onSubmit] — called with validated form values so the caller can confirm.
void showReminderBottomSheet({
  required BuildContext context,
  Reminder? existing,
  required void Function({
    required String name,
    required String description,
    required DateTime startDate,
    required int triggerHour,
    required int triggerMinute,
    required ReminderFrequency frequency,
    required int customIntervalDays,
  }) onSubmit,
}) {
  final isEdit = existing != null;

  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final descCtrl = TextEditingController(text: existing?.description ?? '');
  final customDaysCtrl = TextEditingController(
    text: existing?.customIntervalDays.toString() ?? '7',
  );

  DateTime selectedDate = existing?.startDate ?? DateTime.now();
  int selectedHour = existing?.triggerHour ?? 9;
  int selectedMinute = existing?.triggerMinute ?? 0;
  ReminderFrequency selectedFreq =
      existing?.frequency ?? ReminderFrequency.monthly;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          // ── Date picker ─────────────────────────────────────────────────
          Future<void> pickDate() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: selectedDate,
              firstDate:
                  DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );
            if (picked != null) setSheet(() => selectedDate = picked);
          }

          // ── Time picker ─────────────────────────────────────────────────
          Future<void> pickTime() async {
            final picked = await showTimePicker(
              context: ctx,
              initialTime:
                  TimeOfDay(hour: selectedHour, minute: selectedMinute),
              builder: (context, child) {
                // Wrap in MediaQuery to force 12-hour clock display
                return MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(alwaysUse24HourFormat: false),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setSheet(() {
                selectedHour = picked.hour;
                selectedMinute = picked.minute;
              });
            }
          }

          // Formatted display strings
          final dateLabel =
              DateFormat('dd MMM yyyy').format(selectedDate);
          final tod = TimeOfDay(hour: selectedHour, minute: selectedMinute);
          final timeLabel = tod.format(ctx); // e.g. "9:00 AM" / "3:45 PM"

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Handle ─────────────────────────────────────────────
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin:
                            const EdgeInsets.only(top: 8, bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // ── Header ─────────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_notifications_rounded
                                : Icons.add_alarm_rounded,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Edit Reminder' : 'Add Reminder',
                              style: GoogleFonts.urbanist(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isEdit
                                  ? 'Update reminder details'
                                  : 'Set a new financial reminder',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Reminder Name ──────────────────────────────────────
                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Reminder Name',
                        hintText:
                            'e.g. Pay School Fees, Electricity Bill',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Description ────────────────────────────────────────
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g. Remember son\'s school fee',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Start Date + Trigger Time (side by side) ───────────
                    Row(
                      children: [
                        // Date picker
                        Expanded(
                          child: GestureDetector(
                            onTap: pickDate,
                            child: AbsorbPointer(
                              child: TextField(
                                readOnly: true,
                                controller: TextEditingController(
                                  text: dateLabel,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  prefixIcon: Icon(
                                    Icons.calendar_today_rounded,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.arrow_drop_down_rounded,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Time picker
                        Expanded(
                          child: GestureDetector(
                            onTap: pickTime,
                            child: AbsorbPointer(
                              child: TextField(
                                readOnly: true,
                                controller: TextEditingController(
                                  text: timeLabel,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Trigger Time',
                                  prefixIcon: const Icon(
                                    Icons.access_time_rounded,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.arrow_drop_down_rounded,
                                  ),
                                  // Highlight border when a non-default time
                                  // is set so user knows it's active
                                  enabledBorder: (selectedHour != 9 ||
                                          selectedMinute != 0)
                                      ? OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: accentColor
                                                .withOpacity(0.6),
                                            width: 1.5,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Frequency label ────────────────────────────────────
                    Text(
                      'Frequency',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _FrequencySelector(
                      selected: selectedFreq,
                      onChanged: (f) =>
                          setSheet(() => selectedFreq = f),
                    ),

                    // ── Custom interval ────────────────────────────────────
                    if (selectedFreq == ReminderFrequency.custom) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: customDaysCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Repeat every N days',
                          hintText: 'e.g. 14',
                          prefixIcon: Icon(Icons.repeat_rounded),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Action buttons ─────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              final name = nameCtrl.text.trim();
                              final desc = descCtrl.text.trim();
                              final customDays =
                                  int.tryParse(customDaysCtrl.text) ??
                                      7;

                              if (name.isEmpty) {
                                AppToast.warning(context,
                                    'Please enter a reminder name');
                                return;
                              }
                              if (selectedFreq ==
                                      ReminderFrequency.custom &&
                                  customDays < 1) {
                                AppToast.warning(
                                  context,
                                  'Custom interval must be at least 1 day',
                                );
                                return;
                              }

                              Navigator.pop(ctx);
                              onSubmit(
                                name: name,
                                description: desc,
                                startDate: selectedDate,
                                triggerHour: selectedHour,
                                triggerMinute: selectedMinute,
                                frequency: selectedFreq,
                                customIntervalDays: customDays,
                              );
                            },
                            child: const Text('Continue ›'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ── Frequency Selector Widget ─────────────────────────────────────────────────

class _FrequencySelector extends StatelessWidget {
  final ReminderFrequency selected;
  final ValueChanged<ReminderFrequency> onChanged;

  const _FrequencySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReminderFrequency.values.map((freq) {
        final isSelected = selected == freq;
        return GestureDetector(
          onTap: () => onChanged(freq),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : accentColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Text(
              freq.label,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : accentColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}