// ─── Keys for SmartNotificationService tracking ───────────────────────────────
// These keys are separate from the notification list itself — they track *when*
// a given smart-check was last triggered to avoid duplicate alerts.
class NotificationKeys {
  NotificationKeys._();

  static const transactions = 'transactions';
  static const budgets = 'budgets';
  static const savings = 'savings';
  static const totalIncome = 'total_income';
  static const streakCount = 'streak_count';
  static const lastSaveDate = 'last_save_date';
  static const lastAppOpen = 'last_app_open';

  // Smart-check dedup keys
  static const lastWeeklySummaryDate = 'last_weekly_summary_date';
  static const lastMonthlySummaryDate = 'last_monthly_summary_date';
  static const lastAnalysisDate = 'last_analysis_date';
  static const budgetAlerts = 'budget_alert_flags'; // JSON map
  static const savingsDueAlerts = 'savings_due_alerts'; // JSON list
  static const unusualSpendingAlert = 'unusual_spending_alert_date';
  static const streakReminderDate = 'streak_reminder_date';
  static const inactivityAlertDate = 'inactivity_alert_date';
}
