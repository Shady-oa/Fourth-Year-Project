// ─── Date Preset ─────────────────────────────────────────────────────────────
enum DatePreset {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
  custom,
}

extension DatePresetLabel on DatePreset {
  String get label {
    switch (this) {
      case DatePreset.today:
        return 'Today';
      case DatePreset.thisWeek:
        return 'This Week';
      case DatePreset.thisMonth:
        return 'This Month';
      case DatePreset.lastMonth:
        return 'Last Month';
      case DatePreset.last3Months:
        return '3 Months';
      case DatePreset.thisYear:
        return 'This Year';
      case DatePreset.custom:
        return 'Custom';
    }
  }
}
