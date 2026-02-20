import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PennyFormatter — single centralized currency utility.
//
//  All pages MUST use this class.  No inline NumberFormat calls.
//
//  formatDecimal(v)  → "Ksh 1,234.56"  /  "-Ksh 1,234.56"  (2 dp)
//  format(v)         → "Ksh 1,234"     (whole number, legacy compat)
//  compact(v)        → "Ksh 1.2K" / "Ksh 1.5M"  (tight spaces)
// ─────────────────────────────────────────────────────────────────────────────
class PennyFormatter {
  static final _decimal = NumberFormat('#,##0.00', 'en_US');
  static final _whole = NumberFormat('#,##0', 'en_US');

  /// Primary display format — 2 decimal places, negative sign before "Ksh".
  /// Example: -1234.5 → "-Ksh 1,234.50"
  static String formatDecimal(double amount) {
    final abs = amount.abs();
    final s = _decimal.format(abs);
    return amount < 0 ? '-Ksh $s' : 'Ksh $s';
  }

  /// Whole-number format for compact / legacy contexts.
  /// Example: 1234.0 → "Ksh 1,234"
  static String format(double amount) {
    final abs = amount.abs();
    final s = _whole.format(abs.round());
    return amount < 0 ? '-Ksh $s' : 'Ksh $s';
  }

  /// Abbreviated format for very tight UI spaces.
  /// Example: 1_500_000 → "Ksh 1.5M"  |  2500 → "Ksh 2.5K"
  static String compact(double amount) {
    final abs = amount.abs();
    String s;
    if (abs >= 1_000_000) {
      s = 'Ksh ${(abs / 1_000_000).toStringAsFixed(1)}M';
    } else if (abs >= 1_000) {
      s = 'Ksh ${(abs / 1_000).toStringAsFixed(1)}K';
    } else {
      s = formatDecimal(abs);
    }
    return amount < 0 ? '-$s' : s;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CurrencyFormatter — backwards compat shim so existing per-file classes
//  that use `CurrencyFormatter.format()` still compile without changes.
//  All new code should use PennyFormatter directly.
// ─────────────────────────────────────────────────────────────────────────────
class CurrencyFormatter {
  static String format(double amount) => PennyFormatter.format(amount);
  static String formatDecimal(double amount) =>
      PennyFormatter.formatDecimal(amount);
  static String compact(double amount) => PennyFormatter.compact(amount);
}
