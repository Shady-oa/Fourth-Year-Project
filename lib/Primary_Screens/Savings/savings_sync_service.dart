// ─────────────────────────────────────────────────────────────────────────────
// Primary_Screens/Savings/savings_sync_service.dart
//
// Firestore paths:
//   /statistics/{uid}/{year}/{month}/savings/{savingId}
//   /statistics/{uid}/{year}/{month}/transactions/{auto-id}
//       (fund deposits/withdrawals — filterable by refId = savingId)
//
// Sync strategy — identical pattern to BudgetSyncService:
//
//   WRITES (SharedPreferences first, always):
//     • Every create/edit/delete marks the goal isDirty = true and saves to
//       SharedPreferences immediately — works fully offline.
//     • Deleted goal IDs are recorded in a persistent 'savings_deleted_ids'
//       list so pullAndMerge() never re-adds them.
//     • Pending Firestore transaction writes (deposits/withdrawals made
//       offline) are queued in 'pending_saving_transactions' and replayed
//       when back online.
//     • syncDirtyGoals() is write-only — never reads Firestore — so it is
//       100% safe to call offline (errors are caught silently, isDirty stays
//       true and retries on the next call).
//
//   READS — two-way reconciliation (Firestore ↔ SharedPreferences):
//     • pullAndMerge() removes local goals deleted remotely (unless dirty),
//       refreshes transactions for synced goals, and adds remote-only goals.
//     • Offline: Firestore fetch throws, SharedPreferences left untouched.
//
//   STREAKS:
//     • saveStreak() writes streak count, level and last-save-date to both
//       SharedPreferences and the user's Firestore streak doc.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Primary_Screens/home/home_sync_service.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavingsSyncService {
  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String _keySavings = 'savings';
  static const String _keyDeletedIds = 'savings_deleted_ids';

  /// JSON list of pending Firestore transaction writes:
  /// [ { savingId, type, name, amount, transactionCost, goalName, createdAt,
  ///     year, month } ]
  static const String _keyPendingTx = 'pending_saving_transactions';

  // Streak keys (same as savings_helpers.dart)
  static const String _keyStreakCount = 'streak_count';
  static const String _keyStreakLevel = 'streak_level';
  static const String _keyLastSaveDate = 'last_save_date';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  SavingsSyncService({required this.uid});

  // ── Firestore path helpers ────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _savingsCol({
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
        .collection('savings');
  }

  CollectionReference<Map<String, dynamic>> _transactionsCol({
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

  // ── SharedPreferences helpers ─────────────────────────────────────────────

  Future<List<Saving>> _loadLocalSavings() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keySavings) ?? [])
        .map((s) => Saving.fromMap(json.decode(s)))
        .toList();
  }

  Future<void> _saveLocalSavings(List<Saving> savings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keySavings,
      savings.map((s) => json.encode(s.toMap())).toList(),
    );
  }

  // Deleted IDs ---------------------------------------------------------------

  Future<Set<String>> _loadDeletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDeletedIds);
    if (raw == null) return {};
    return Set<String>.from(json.decode(raw) as List);
  }

  Future<void> _recordDeletedId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await _loadDeletedIds();
    ids.add(id);
    await prefs.setString(_keyDeletedIds, json.encode(ids.toList()));
  }

  // Pending transactions -------------------------------------------------------

  Future<List<Map<String, dynamic>>> _loadPendingTx() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingTx);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(raw));
  }

  Future<void> _savePendingTx(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingTx, json.encode(list));
  }

  /// Queues a Firestore transaction write for a deposit or withdrawal.
  /// The entry is persisted immediately to SharedPreferences so it survives
  /// a cold restart and is replayed when back online.
  Future<void> queueTransaction({
    required String savingId,
    required String type, // 'saving_deposit' | 'savings_withdrawal'
    required String name, // e.g. 'Saved for Vacation'
    required double amount,
    required double transactionCost,
    required String goalName,
    required String refId, // = savingId, used to filter per-goal in Firestore
    String reason = '',
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final pending = await _loadPendingTx();
    pending.add({
      'savingId': savingId,
      'type': type,
      'name': name,
      'amount': amount,
      'transactionCost': transactionCost,
      'goalName': goalName,
      'refId': refId,
      'reason': reason,
      'date': now.toIso8601String(),
      'createdAt': now.toIso8601String(),
      'year': year ?? now.year,
      'month': month ?? now.month,
    });
    await _savePendingTx(pending);
  }

  // ── Firestore write helpers ───────────────────────────────────────────────

  /// Pushes all saving goal fields to Firestore (no transactions embedded).
  Future<void> _pushSavingDoc(Saving saving, {int? year, int? month}) async {
    final data = saving.toMap()
      ..remove('transactions') // stored in global transactions collection
      ..remove('isDirty');     // local-only flag
    await _savingsCol(year: year, month: month)
        .doc(saving.id)
        .set(data, SetOptions(merge: true));
  }

  /// Replays all pending Firestore transaction writes.
  /// Removes entries from the pending list only on success.
  Future<void> _replayPendingTransactions() async {
    final pending = await _loadPendingTx();
    if (pending.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];

    for (final entry in pending) {
      try {
        final y = entry['year'] as int?;
        final m = entry['month'] as int?;
        await _transactionsCol(year: y, month: m).add({
          'title': entry['name'],       // unified field name
          'name': entry['name'],        // kept for backwards compat
          'amount': entry['amount'],
          'transactionCost': entry['transactionCost'] ?? 0.0,
          'type': entry['type'],
          'source': TxSource.savings,   // identifies savings as the writer
          'reason': entry['reason'] ?? '',
          'refId': entry['refId'],      // savingId — used to filter per goal
          'goalName': entry['goalName'],
          'date': entry['date'] ?? DateTime.now().toIso8601String(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        remaining.add(entry); // keep — retry next time
        debugPrint('[SavingsSyncService] Could not replay tx: $e');
      }
    }

    await _savePendingTx(remaining);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Pushes every dirty saving goal to Firestore and replays pending
  /// transaction writes.
  ///
  /// Write-only — never reads Firestore, safe to call offline.
  /// isDirty stays true on failure, retries on next call.
  Future<void> syncDirtyGoals({int? year, int? month}) async {
    final savings = await _loadLocalSavings();
    bool anyChange = false;

    for (final saving in savings) {
      if (!saving.isDirty) continue;
      try {
        await _pushSavingDoc(saving, year: year, month: month);
        saving.isDirty = false;
        anyChange = true;
        debugPrint('[SavingsSyncService] Synced goal: ${saving.name}');
      } catch (e) {
        debugPrint('[SavingsSyncService] Sync failed for "${saving.name}": $e');
        // isDirty stays true — retries next call.
      }
    }

    if (anyChange) await _saveLocalSavings(savings);

    // Always try to replay pending transactions regardless of dirty state.
    await _replayPendingTransactions();
  }

  /// Two-way reconciliation between Firestore and SharedPreferences.
  ///
  ///  1. Local goals not in Firestore (and not dirty) → removed locally.
  ///  2. Local goals in Firestore and not dirty → metadata refreshed.
  ///  3. Goals in Firestore but not local → added to SharedPreferences.
  ///  4. Goals in deleted-IDs list → never re-added.
  ///
  /// If offline the Firestore fetch throws and SharedPreferences is untouched.
  Future<void> pullAndMerge({int? year, int? month}) async {
    try {
      final now = DateTime.now();
      final y = year ?? now.year;
      final m = month ?? now.month;

      final snap = await _savingsCol(year: y, month: m).get();
      final remoteIds = {for (final doc in snap.docs) doc.id};
      final deletedIds = await _loadDeletedIds();
      final localSavings = await _loadLocalSavings();

      final reconciled = <Saving>[];
      bool anyChange = false;

      // ── Step 1: walk local savings ────────────────────────────────────
      for (final local in localSavings) {
        if (remoteIds.contains(local.id)) {
          if (!local.isDirty) {
            // Refresh metadata from Firestore (name, target, deadline, etc.)
            // Transactions stay as-is in local model (they live in global
            // transactions collection in Firestore, not embedded in the doc).
            final remoteDoc = snap.docs.firstWhere((d) => d.id == local.id);
            final data = Map<String, dynamic>.from(remoteDoc.data());
            data['id'] = local.id;
            data['isDirty'] = false;
            // Preserve local transaction history (not stored in savings doc)
            data['transactions'] =
                local.transactions.map((t) => t.toMap()).toList();
            reconciled.add(Saving.fromMap(data));
            anyChange = true;
          } else {
            reconciled.add(local); // dirty — local is authoritative
          }
        } else {
          if (local.isDirty) {
            // Created/edited offline — keep, will push via syncDirtyGoals.
            reconciled.add(local);
            debugPrint(
                '[SavingsSyncService] Keeping offline goal: ${local.name}');
          } else {
            // Clean goal not in Firestore — deleted remotely.
            anyChange = true;
            debugPrint(
                '[SavingsSyncService] Removing locally (deleted remotely): ${local.name}');
          }
        }
      }

      // ── Step 2: add goals in Firestore but missing locally ────────────
      final reconciledIds = {for (final s in reconciled) s.id};
      for (final doc in snap.docs) {
        if (deletedIds.contains(doc.id)) continue;
        if (reconciledIds.contains(doc.id)) continue;

        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        data['isDirty'] = false;
        data['transactions'] = <dynamic>[]; // local tx history starts empty

        reconciled.add(Saving.fromMap(data));
        anyChange = true;
        debugPrint(
            '[SavingsSyncService] Pulled new goal from Firestore: ${data['name']}');
      }

      if (anyChange) await _saveLocalSavings(reconciled);
    } catch (e) {
      debugPrint('[SavingsSyncService] pullAndMerge error: $e');
    }
  }

  /// Deletes a saving goal from Firestore and records its ID so
  /// pullAndMerge() never re-adds it.
  Future<void> deleteGoalRemote(Saving saving, {int? year, int? month}) async {
    await _recordDeletedId(saving.id);

    // Remove any pending transactions for this goal from the queue.
    final pending = await _loadPendingTx();
    pending.removeWhere((e) => e['savingId'] == saving.id);
    await _savePendingTx(pending);

    try {
      await _savingsCol(year: year, month: month).doc(saving.id).delete();
      debugPrint('[SavingsSyncService] Deleted remote goal: ${saving.name}');
    } catch (e) {
      debugPrint('[SavingsSyncService] deleteGoalRemote error: $e');
    }
  }

  // ── Streak sync ───────────────────────────────────────────────────────────

  /// Writes the current streak to Firestore user doc (fire-and-forget).
  /// Always saves to SharedPreferences first (offline-safe).
  Future<void> saveStreak({
    required int count,
    required String level,
    required String lastSaveDate,
  }) async {
    // SharedPreferences is already written by savings_helpers.dart updateStreak.
    // We just push to Firestore here.
    try {
      await _db.collection('users').doc(uid).set({
        'streakCount': count,
        'streakLevel': level,
        'lastSaveDate': lastSaveDate,
        'streakUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[SavingsSyncService] Streak synced: $count days ($level)');
    } catch (e) {
      debugPrint('[SavingsSyncService] saveStreak error: $e');
    }
  }
}