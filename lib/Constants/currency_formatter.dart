import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');
  
  /// Format amount with Ksh prefix and comma separation
  /// Example: 1000000 → "Ksh 1,000,000"
  static String format(double amount) {
    return 'Ksh ${_formatter.format(amount.round())}';
  }
  
  /// Format amount without currency symbol
  /// Example: 1000000 → "1,000,000"
  static String formatWithoutSymbol(double amount) {
    return _formatter.format(amount.round());
  }
}