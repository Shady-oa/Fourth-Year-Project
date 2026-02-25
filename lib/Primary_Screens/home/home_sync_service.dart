// ─────────────────────────────────────────────────────────────────────────────
// Primary_Screens/home/home_sync_service.dart
//
// Firestore path:
//   /statistics/{uid}/{year}/{month}/transactions/{auto-id}
//
// Unified transaction schema — every writer (home, savings, budget) must
// produce exactly these fields so the UI never reads a null field:
//
//   title           String   human-readable label shown in lists
//   amount          double   principal amount (never includes fee)
//   transactionCost double   fee portion (0 if none)
//   type            String   one of the type constants below
//   source          String   'home' | 'savings' | 'budget'
//   reason          String   free-text note ('' if none)
//   refId           String   budget/goal ID for traceability ('' for home)
//   date            String   ISO-8601 local timestamp (used by FinancialService
//                            and SmartNotificationService for date maths)
//   createdAt       Timestamp Firestore server timestamp (used for ordering)
//
// TRANSACTION TYPE CONSTANTS (shared across all pages):
//   'income'             home page income
//   'expense'            home page expense
//   'savings_deduction'  savings deposit (deducted from balance)
//   'saving_deposit'     alias — same meaning, kept for backwards compat
//   'savings_withdrawal' savings withdrawal (restored to balance)
//   'budget'             budget finalised transaction
//   'budget_expense'     individual budget expense (legacy, display-only)
//   'budget_finalized'   alias for 'budget' — kept for backwards compat
//
// Offline strategy — identical pattern to BudgetSyncService/SavingsSyncService:
//   1. Write to SharedPreferences immediately (works offline, instant UI).
//   2. Queue Firestore write in 'pending_home_transactions' SharedPrefs key.
//   3. syncPendingTransactions() replays the queue when back online.
//   4. refreshData() → _syncInBackground() is the single replay entry point.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Type constants ────────────────────────────────────────────────────────────
// Import this class in every page that writes transactions so the strings
// stay consistent and typos are caught at compile time.
class TxType {
  TxType._();
  static const income = 'income';
  static const expense = 'expense';
  static const savingsDeduction = 'savings_deduction';
  static const savingDeposit = 'saving_deposit'; // alias
  static const savingsWithdrawal = 'savings_withdrawal';
  static const budget = 'budget';
  static const budgetExpense = 'budget_expense';
  static const budgetFinalized = 'budget_finalized'; // alias
}

// ── Source constants ──────────────────────────────────────────────────────────
class TxSource {
  TxSource._();
  static const home = 'home';
  static const savings = 'savings';
  static const budget = 'budget';
}

// ── Unified transaction builder ───────────────────────────────────────────────
/// Builds the canonical transaction map that EVERY page must use when writing
/// to SharedPreferences.  Pass this to json.encode and store it.
///
/// [date] defaults to now.  Pass an explicit value when replaying old entries.
Map<String, dynamic> buildTxMap({
  required String title,
  required double amount,
  required String type,
  required String source,
  double transactionCost = 0.0,
  String reason = '',
  String refId = '',
  DateTime? date,
}) {
  return {
    'title': title,
    'amount': amount,
    'transactionCost': transactionCost,
    'type': type,
    'source': source,
    'reason': reason,
    'refId': refId,
    // 'date' is the ISO-8601 string used by FinancialService and
    // SmartNotificationService for date maths — must always be present.
    'date': (date ?? DateTime.now()).toIso8601String(),
    // 'createdAt' mirrors 'date' locally so SmartNotificationService
    // _txDate() finds it without needing a fallback.
    'createdAt': (date ?? DateTime.now()).toIso8601String(),
  };
}

// ── HomeSyncService ───────────────────────────────────────────────────────────
class HomeSyncService {
  static const String _keyPendingTx = 'pending_home_transactions';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  HomeSyncService({required this.uid});

  // ── Firestore path ──────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> _txCol({
    int? year,
    int? month,
  }) {
    final now = DateTime.now();
    final y = (year ?? now.year).toString();
    final m = (month ?? now.month).toString().padLeft(2, '0');
    return _db
        .collection('statistics')
        .doc(uid)
        .collection(y)
        .doc(m)
        .collection('transactions');
  }

  // ── Pending queue ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingTx);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(raw));
  }

  Future<void> _savePending(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingTx, json.encode(list));
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Queues a single Firestore transaction write.
  /// Always call this AFTER writing to SharedPreferences and BEFORE
  /// triggering a sync, so the entry is on disk if the app is killed.
  Future<void> queueTransaction({
    required String title,
    required double amount,
    required String type,
    required String source,
    double transactionCost = 0.0,
    String reason = '',
    String refId = '',
    DateTime? date,
    int? year,
    int? month,
  }) async {
    final now = date ?? DateTime.now();
    final pending = await _loadPending();
    pending.add({
      'title': title,
      'amount': amount,
      'transactionCost': transactionCost,
      'type': type,
      'source': source,
      'reason': reason,
      'refId': refId,
      'date': now.toIso8601String(),
      'year': year ?? now.year,
      'month': month ?? now.month,
    });
    await _savePending(pending);
  }

  /// Replays all pending Firestore writes.
  /// Only removes entries from the queue on success so nothing is lost offline.
  Future<void> syncPendingTransactions() async {
    final pending = await _loadPending();
    if (pending.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];

    for (final entry in pending) {
      try {
        final y = entry['year'] as int?;
        final m = entry['month'] as int?;
        await _txCol(year: y, month: m).add({
          'title': entry['title'],
          'amount': entry['amount'],
          'transactionCost': entry['transactionCost'] ?? 0.0,
          'type': entry['type'],
          'source': entry['source'] ?? TxSource.home,
          'reason': entry['reason'] ?? '',
          'refId': entry['refId'] ?? '',
          'date': entry['date'],
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[HomeSyncService] Synced tx: ${entry['title']}');
      } catch (e) {
        remaining.add(entry);
        debugPrint('[HomeSyncService] Sync failed for "${entry['title']}": $e');
      }
    }

    await _savePending(remaining);
  }
}