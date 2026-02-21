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
