extension DateTimeExtension on DateTime {
  DateTime lastDayOfMonth() {
    return DateTime(this.year, this.month + 1, 0);
  }
}
