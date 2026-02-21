import 'package:final_project/SecondaryScreens/Notifications/notification_type.dart';
import 'package:uuid/uuid.dart';

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
