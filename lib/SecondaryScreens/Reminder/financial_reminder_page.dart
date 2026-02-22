// ─────────────────────────────────────────────────────────────────────────────
// SecondaryScreens/Reminders/financial_reminder_page.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_type.dart';
import 'package:final_project/SecondaryScreens/Reminder/reminder_bottom_sheet.dart';
import 'package:final_project/SecondaryScreens/Reminder/reminder_card.dart';
import 'package:final_project/SecondaryScreens/Reminder/reminder_confirmation_sheet.dart';
import 'package:final_project/SecondaryScreens/Reminder/reminder_model.dart';
import 'package:final_project/SecondaryScreens/Reminder/reminder_storage.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ── Filter enum ───────────────────────────────────────────────────────────────

enum _ReminderFilter { all, active, inactive }

extension _ReminderFilterX on _ReminderFilter {
  String get label {
    switch (this) {
      case _ReminderFilter.all:
        return 'All';
      case _ReminderFilter.active:
        return 'Active';
      case _ReminderFilter.inactive:
        return 'Inactive';
    }
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class FinancialReminderPage extends StatefulWidget {
  const FinancialReminderPage({super.key});

  @override
  State<FinancialReminderPage> createState() => _FinancialReminderPageState();
}

class _FinancialReminderPageState extends State<FinancialReminderPage> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  _ReminderFilter _filter = _ReminderFilter.all;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(
      () => setState(
          () => _searchQuery = _searchCtrl.text.trim().toLowerCase()),
    );
    _searchFocus.addListener(
      () => setState(() => _isSearchFocused = _searchFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await ReminderStorage.fetchAll();
    setState(() {
      _reminders = list;
      _isLoading = false;
    });
  }

  // ── Filtered list ─────────────────────────────────────────────────────────

  List<Reminder> get _filtered {
    List<Reminder> result = _reminders;
    switch (_filter) {
      case _ReminderFilter.active:
        result = result.where((r) => r.isActive).toList();
        break;
      case _ReminderFilter.inactive:
        result = result.where((r) => !r.isActive).toList();
        break;
      case _ReminderFilter.all:
        break;
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((r) => r.name.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return result;
  }

  // ── Notification helper ───────────────────────────────────────────────────

  Future<void> _pushNotification(String title, String message) =>
      LocalNotificationStore.saveNotification(
        title: title,
        message: message,
        type: NotificationType.reminder,
      );

  // ── Add ───────────────────────────────────────────────────────────────────

  void _showAddSheet() {
    showReminderBottomSheet(
      context: context,
      onSubmit: ({
        required String name,
        required String description,
        required DateTime startDate,
        required int triggerHour,
        required int triggerMinute,
        required ReminderFrequency frequency,
        required int customIntervalDays,
      }) {
        final dateFormat = DateFormat('dd MMM yyyy');
        final reminder = Reminder(
          name: name,
          description: description,
          startDate: startDate,
          frequency: frequency,
          customIntervalDays: customIntervalDays,
          triggerHour: triggerHour,
          triggerMinute: triggerMinute,
        );

        showReminderConfirmSheet(
          context: context,
          title: 'Confirm Reminder',
          icon: Icons.add_alarm_rounded,
          iconColor: accentColor,
          rows: [
            ReminderConfirmRow('Name', name, highlight: true),
            ReminderConfirmRow('Start Date', dateFormat.format(startDate)),
            ReminderConfirmRow('Trigger Time', reminder.triggerTimeLabel),
            ReminderConfirmRow('Frequency', frequency.label),
            if (frequency == ReminderFrequency.custom)
              ReminderConfirmRow(
                  'Interval', 'Every $customIntervalDays days'),
            if (description.isNotEmpty)
              ReminderConfirmRow('Description', description),
          ],
          confirmLabel: 'Set Reminder',
          confirmColor: accentColor,
          onConfirm: () async {
            await ReminderStorage.add(reminder);
            await _pushNotification(
              'Reminder Set: $name',
              '${frequency.label} reminder at ${reminder.triggerTimeLabel}. '
              'First trigger: ${dateFormat.format(reminder.nextTriggerDate)}.'
              '${description.isNotEmpty ? '  "$description"' : ''}',
            );
            await _load();
            if (mounted) AppToast.success(context, 'Reminder "$name" set!');
          },
        );
      },
    );
  }

  // ── Edit ──────────────────────────────────────────────────────────────────

  void _showEditSheet(Reminder reminder) {
    showReminderBottomSheet(
      context: context,
      existing: reminder,
      onSubmit: ({
        required String name,
        required String description,
        required DateTime startDate,
        required int triggerHour,
        required int triggerMinute,
        required ReminderFrequency frequency,
        required int customIntervalDays,
      }) {
        final dateFormat = DateFormat('dd MMM yyyy');
        final updated = Reminder(
          id: reminder.id,
          name: name,
          description: description,
          startDate: startDate,
          frequency: frequency,
          customIntervalDays: customIntervalDays,
          triggerHour: triggerHour,
          triggerMinute: triggerMinute,
          createdAt: reminder.createdAt,
          isActive: reminder.isActive,
        );

        showReminderConfirmSheet(
          context: context,
          title: 'Confirm Edit',
          icon: Icons.edit_notifications_rounded,
          iconColor: accentColor,
          rows: [
            ReminderConfirmRow('Name', name, highlight: true),
            ReminderConfirmRow('Start Date', dateFormat.format(startDate)),
            ReminderConfirmRow('Trigger Time', updated.triggerTimeLabel),
            ReminderConfirmRow('Frequency', frequency.label),
            if (frequency == ReminderFrequency.custom)
              ReminderConfirmRow(
                  'Interval', 'Every $customIntervalDays days'),
            if (description.isNotEmpty)
              ReminderConfirmRow('Description', description),
          ],
          confirmLabel: 'Save Changes',
          confirmColor: accentColor,
          onConfirm: () async {
            await ReminderStorage.update(updated);
            await _pushNotification(
              'Reminder Updated: $name',
              'Now triggers ${frequency.label.toLowerCase()} at '
              '${updated.triggerTimeLabel}. '
              'Next: ${dateFormat.format(updated.nextTriggerDate)}.',
            );
            await _load();
            if (mounted) AppToast.success(context, 'Reminder updated!');
          },
        );
      },
    );
  }

  // ── Toggle Active ─────────────────────────────────────────────────────────

  void _confirmToggleActive(Reminder reminder) {
    final isActive = reminder.isActive;
    final dateFormat = DateFormat('dd MMM yyyy');

    showReminderConfirmSheet(
      context: context,
      title: isActive ? 'Deactivate Reminder' : 'Activate Reminder',
      icon: isActive
          ? Icons.pause_circle_outline_rounded
          : Icons.play_circle_outline_rounded,
      iconColor: isActive ? Colors.orange.shade700 : brandGreen,
      rows: [
        ReminderConfirmRow('Reminder', reminder.name, highlight: true),
        ReminderConfirmRow('Frequency', reminder.frequency.label),
        ReminderConfirmRow('Trigger Time', reminder.triggerTimeLabel),
        ReminderConfirmRow(
            'Next Trigger', dateFormat.format(reminder.nextTriggerDate)),
        ReminderConfirmRow(
            'New Status', isActive ? 'Inactive (paused)' : 'Active (running)'),
      ],
      note: isActive
          ? 'The reminder will stop triggering until you activate it again.'
          : 'The reminder will resume triggering on its schedule.',
      confirmLabel: isActive ? 'Deactivate' : 'Activate',
      confirmColor: isActive ? Colors.orange.shade700 : brandGreen,
      onConfirm: () async {
        final newState = await ReminderStorage.toggleActive(reminder.id);
        if (newState == null) return;
        await _pushNotification(
          newState
              ? 'Reminder Activated: ${reminder.name}'
              : 'Reminder Deactivated: ${reminder.name}',
          newState
              ? '"${reminder.name}" will now trigger ${reminder.frequency.label.toLowerCase()} at ${reminder.triggerTimeLabel}.'
              : '"${reminder.name}" has been paused and will not trigger until reactivated.',
        );
        await _load();
        if (mounted) {
          AppToast.success(
            context,
            newState
                ? '"${reminder.name}" activated'
                : '"${reminder.name}" deactivated',
          );
        }
      },
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  void _showDeleteConfirm(Reminder reminder) {
    final dateFormat = DateFormat('dd MMM yyyy');
    showReminderConfirmSheet(
      context: context,
      title: 'Delete Reminder',
      icon: Icons.delete_outline_rounded,
      iconColor: errorColor,
      rows: [
        ReminderConfirmRow('Name', reminder.name, highlight: true),
        ReminderConfirmRow('Frequency', reminder.frequency.label),
        ReminderConfirmRow('Trigger Time', reminder.triggerTimeLabel),
        ReminderConfirmRow(
            'Next Due', dateFormat.format(reminder.nextTriggerDate)),
      ],
      note: 'This reminder will be permanently removed.',
      confirmLabel: 'Delete Reminder',
      confirmColor: errorColor,
      onConfirm: () async {
        final name = reminder.name;
        await ReminderStorage.delete(reminder.id);
        await _pushNotification(
          'Reminder Deleted: $name',
          'The "$name" (${reminder.frequency.label}) reminder has been permanently removed.',
        );
        await _load();
        if (mounted) AppToast.success(context, 'Reminder deleted');
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Reminders',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Search bar ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search reminders…',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color:
                            _isSearchFocused ? brandGreen : Colors.grey,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                _searchFocus.unfocus();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              theme.colorScheme.onSurface.withAlpha(40),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: brandGreen, width: 2),
                      ),
                    ),
                  ),
                ),

                // ── Filter chips ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: _ReminderFilter.values.map((f) {
                      final selected = _filter == f;
                      final count = f == _ReminderFilter.all
                          ? _reminders.length
                          : f == _ReminderFilter.active
                              ? _reminders
                                  .where((r) => r.isActive)
                                  .length
                              : _reminders
                                  .where((r) => !r.isActive)
                                  .length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected
                                  ? _filterColor(f)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? _filterColor(f)
                                    : _filterColor(f).withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  f.label,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : _filterColor(f),
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.white.withOpacity(0.25)
                                          : _filterColor(f)
                                              .withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: selected
                                            ? Colors.white
                                            : _filterColor(f),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // ── List ───────────────────────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(theme)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final r = filtered[i];
                              return ReminderCard(
                                reminder: r,
                                onEdit: () => _showEditSheet(r),
                                onToggleActive: () =>
                                    _confirmToggleActive(r),
                                onDelete: () => _showDeleteConfirm(r),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: accentColor,
        child: const Icon(Icons.add_alarm_rounded, color: Colors.white),
      ),
    );
  }

  Color _filterColor(_ReminderFilter f) {
    switch (f) {
      case _ReminderFilter.all:
        return accentColor;
      case _ReminderFilter.active:
        return brandGreen;
      case _ReminderFilter.inactive:
        return Colors.grey.shade500;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    final isSearch = _searchQuery.isNotEmpty;
    final isFiltered = _filter != _ReminderFilter.all;

    final mainLabel = isSearch
        ? 'No reminders match "$_searchQuery"'
        : isFiltered
            ? 'No ${_filter.label.toLowerCase()} reminders'
            : 'No reminders yet';

    final subLabel = isSearch
        ? 'Try a different search term'
        : isFiltered
            ? (_filter == _ReminderFilter.active
                ? 'All your reminders are currently inactive'
                : 'All your reminders are currently active')
            : 'Tap + to set your first financial reminder';

    final icon = isSearch
        ? Icons.search_off_rounded
        : isFiltered && _filter == _ReminderFilter.inactive
            ? Icons.check_circle_outline_rounded
            : Icons.alarm_off_rounded;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            mainLabel,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subLabel,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}