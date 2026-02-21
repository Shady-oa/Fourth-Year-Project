import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ─── Notification Types ────────────────────────────────────────────────────────
enum NotificationType {
  budget,
  savings,
  streak,
  analysis,
  report,
  insight,
  system,
}

extension NotificationTypeX on NotificationType {
  /// Serialisation value stored in JSON
  String get value {
    switch (this) {
      case NotificationType.budget:
        return 'budget';
      case NotificationType.savings:
        return 'savings';
      case NotificationType.streak:
        return 'streak';
      case NotificationType.analysis:
        return 'analysis';
      case NotificationType.report:
        return 'report';
      case NotificationType.insight:
        return 'insight';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromString(String? v) {
    switch (v) {
      case 'budget':
        return NotificationType.budget;
      case 'savings':
        return NotificationType.savings;
      case 'streak':
        return NotificationType.streak;
      case 'analysis':
        return NotificationType.analysis;
      case 'report':
        return NotificationType.report;
      case 'insight':
        return NotificationType.insight;
      default:
        return NotificationType.system;
    }
  }

  String get label {
    switch (this) {
      case NotificationType.budget:
        return 'Budget';
      case NotificationType.savings:
        return 'Savings';
      case NotificationType.streak:
        return 'Streak';
      case NotificationType.analysis:
        return 'Analysis';
      case NotificationType.report:
        return 'Report';
      case NotificationType.insight:
        return 'Insight';
      case NotificationType.system:
        return 'System';
    }
  }
}

// ─── AppNotification Model ─────────────────────────────────────────────────────
/// Immutable-ish data class representing a single notification entry.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  /// Serialise to a JSON-safe map for SharedPreferences storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type.value,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
  };

  /// Deserialise from the stored JSON map.
  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String? ?? const Uuid().v4(),
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        type: NotificationTypeX.fromString(json['type'] as String?),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
      );

  /// Create a copy with updated fields.
  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}

// ─── Local Notification Store ─────────────────────────────────────────────────
/// Central local-storage service for app notifications.
///
/// All reads/writes go through SharedPreferences — fully offline.
/// Call [LocalNotificationStore.saveNotification] from anywhere in the app
/// (SmartNotificationService, savings.dart, budget.dart, home.dart) to add a
/// notification that will appear on the Notifications page.
///
/// The [unreadCountNotifier] is a [ValueNotifier<int>] that widgets can listen
/// to in order to keep badge counters up-to-date without polling.
class LocalNotificationStore {
  LocalNotificationStore._(); // singleton — use static API only

  static const _prefKey = 'app_notifications';
  static const _uuid = Uuid();

  /// Reactive unread count — updates whenever the store changes.
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier(0);

  // ── Internal helpers ────────────────────────────────────────────────────────

  /// Load raw list from SharedPreferences.
  static Future<List<AppNotification>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey) ?? '[]';
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Persist the given list to SharedPreferences and refresh [unreadCountNotifier].
  static Future<void> _save(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_prefKey, encoded);
    _refreshCount(notifications);
  }

  /// Update the ValueNotifier from an already loaded list (avoids extra I/O).
  static void _refreshCount(List<AppNotification> notifications) {
    unreadCountNotifier.value = notifications.where((n) => !n.isRead).length;
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Save a new notification. Prepends to the list so newest is first.
  ///
  /// [dedupKey] is an optional string; if provided and a notification with the
  /// same key exists in the last 24 hours, the save is skipped (prevents
  /// duplicate alerts for the same event).
  static Future<void> saveNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? dedupKey,
  }) async {
    final notifications = await _load();

    // Deduplication guard
    if (dedupKey != null) {
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      final alreadyExists = notifications.any(
        (n) => n.title == title && n.createdAt.isAfter(cutoff),
      );
      if (alreadyExists) return;
    }

    notifications.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        isRead: false,
      ),
    );

    // Auto-prune notifications older than 30 days to keep storage tidy
    await _save(_pruneOld(notifications));
  }

  /// Fetch all notifications, newest first.
  static Future<List<AppNotification>> fetchNotifications() async {
    final notifications = await _load();
    _refreshCount(notifications);
    return notifications;
  }

  /// Mark a single notification as read by [id].
  static Future<void> markAsRead(String id) async {
    final notifications = await _load();
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx] = notifications[idx].copyWith(isRead: true);
      await _save(notifications);
    }
  }

  /// Mark every notification as read.
  static Future<void> markAllAsRead() async {
    final notifications = await _load();
    final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _save(updated);
  }

  /// Delete a single notification by [id].
  static Future<void> deleteNotification(String id) async {
    final notifications = await _load();
    notifications.removeWhere((n) => n.id == id);
    await _save(notifications);
  }

  /// Clear all notifications from storage.
  static Future<void> clearAll() async {
    await _save([]);
  }

  /// Initialise the ValueNotifier on app start without adding a notification.
  static Future<void> init() async {
    final notifications = await _load();
    _refreshCount(notifications);
  }

  // ── Auto-prune ──────────────────────────────────────────────────────────────

  /// Remove notifications older than [days] days.
  static List<AppNotification> _pruneOld(
    List<AppNotification> list, {
    int days = 30,
  }) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return list.where((n) => n.createdAt.isAfter(cutoff)).toList();
  }

  /// Public pruning call — can be called from settings if auto-prune is toggled.
  static Future<void> pruneOld({int days = 30}) async {
    final notifications = await _load();
    await _save(_pruneOld(notifications, days: days));
  }
}
