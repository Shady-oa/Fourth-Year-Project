extension DateTimeExtension on DateTime {
  DateTime lastDayOfMonth() {
    return DateTime(year, month + 1, 0);
  }
}
