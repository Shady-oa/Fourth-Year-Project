// ─────────────────────────────────────────────────────────────────────────────
// SecondaryScreens/Reminders/reminder_storage.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:final_project/SecondaryScreens/Reminder/reminder_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-storage layer for [Reminder] objects.
/// All reads/writes go through SharedPreferences — fully offline.
class ReminderStorage {
  ReminderStorage._();

  static const _prefKey = 'financial_reminders';

  // ── Internal helpers ────────────────────────────────────────────────────────

  static Future<List<Reminder>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey) ?? '[]';
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> _save(List<Reminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_prefKey, encoded);
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Fetch all reminders, newest first.
  static Future<List<Reminder>> fetchAll() => _load();

  /// Add a new reminder (prepended so newest shows first).
  static Future<void> add(Reminder reminder) async {
    final list = await _load();
    list.insert(0, reminder);
    await _save(list);
  }

  /// Update an existing reminder by id. No-op if not found.
  static Future<void> update(Reminder updated) async {
    final list = await _load();
    final idx = list.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
      await _save(list);
    }
  }

  /// Toggle [isActive] for a reminder by [id]. Returns the new active state,
  /// or null if the reminder was not found.
  static Future<bool?> toggleActive(String id) async {
    final list = await _load();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx == -1) return null;

    final r = list[idx];
    final newActive = !r.isActive;
    list[idx] = Reminder(
      id: r.id,
      name: r.name,
      description: r.description,
      startDate: r.startDate,
      frequency: r.frequency,
      customIntervalDays: r.customIntervalDays,
      nextTriggerDate: r.nextTriggerDate,
      createdAt: r.createdAt,
      isActive: newActive,
    );
    await _save(list);
    return newActive;
  }

  /// Delete a reminder by id.
  static Future<void> delete(String id) async {
    final list = await _load();
    list.removeWhere((r) => r.id == id);
    await _save(list);
  }

  /// Persist the updated nextTriggerDate after a trigger fires.
  static Future<void> advanceTrigger(String id, DateTime next) async {
    final list = await _load();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final r = list[idx];
      list[idx] = Reminder(
        id: r.id,
        name: r.name,
        description: r.description,
        startDate: r.startDate,
        frequency: r.frequency,
        customIntervalDays: r.customIntervalDays,
        nextTriggerDate: next,
        createdAt: r.createdAt,
        isActive: r.isActive,
      );
      await _save(list);
    }
  }
}
