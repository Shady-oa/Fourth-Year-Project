// Currency formatting utility (local copy — full methods)
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimalFmt = NumberFormat('#,##0.00', 'en_US');

  /// Whole-number format:  1234 → "Ksh 1,234"
  static String format(double amount) {
    final abs = amount.abs();
    final s = _formatter.format(abs.round());
    return amount < 0 ? '-Ksh $s' : 'Ksh $s';
  }

  /// Two-decimal format:  1234.5 → "Ksh 1,234.50"
  static String formatDecimal(double amount) {
    final abs = amount.abs();
    final s = _decimalFmt.format(abs);
    return amount < 0 ? '-Ksh $s' : 'Ksh $s';
  }

  static String compact(double amount) {
    final abs = amount.abs();
    String s;
    if (abs >= 1000000) {
      s = 'Ksh ${(abs / 1000000).toStringAsFixed(1)}M';
    } else {
      s = format(abs);
    }
    return amount < 0 ? '-$s' : s;
  }
}
