// ─────────────────────────────────────────────────────────────────────────────
// Primary_Screens/Budgets/budget_sync_service.dart
//
// Firestore path:
//   /statistics/{uid}/{year}/{month}/budgets/{budgetId}
//     └── expenses/{expenseId}
//
// Sync strategy — everything is offline-safe:
//
//   WRITES (SharedPreferences first, always):
//     • Every add/edit/delete of a budget or expense saves to SharedPreferences
//       immediately and sets isDirty = true on the parent budget.
//     • Deleted expenses are recorded in a persistent
//       "pending_expense_deletions" map  {budgetId: [expenseId, ...]}  so the
//       deletion survives a cold restart and is replayed when back online.
//     • syncDirtyBudgets() pushes all dirty budgets + their expenses to
//       Firestore, then replays pending expense deletions, then clears the
//       flags. It never reads from Firestore — pure write path, works offline.
//
//   READS — two-way reconciliation (Firestore ↔ SharedPreferences):
//     • pullAndMerge() fetches the current month from Firestore and:
//         - Removes local budgets that no longer exist in Firestore (deleted
//           remotely via console or another device), UNLESS they are dirty
//           (offline-created/edited — those are kept and pushed later).
//         - Refreshes expenses from Firestore for synced budgets so remote
//           expense deletions are reflected locally.
//         - Adds budgets present in Firestore but missing locally.
//     • If offline the Firestore fetch throws and SharedPreferences is left
//       completely untouched — the app keeps working from local data.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetSyncService {
  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String _keyBudgets = 'budgets';

  /// JSON-encoded List<String> of budget IDs deleted from the app UI.
  /// Prevents pullAndMerge() from re-adding them from Firestore.
  static const String _keyDeletedBudgetIds = 'budgets_deleted_ids';

  /// JSON-encoded Map<String, List<String>>  { budgetId: [expenseId, ...] }
  /// Expense deletions made offline that haven't been replayed to Firestore.
  static const String _keyPendingExpDeletions = 'pending_expense_deletions';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  BudgetSyncService({required this.uid});

  // ── Firestore path helpers ────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _budgetsCol({
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
        .collection('budgets');
  }

  CollectionReference<Map<String, dynamic>> _expensesCol(
    String budgetId, {
    int? year,
    int? month,
  }) =>
      _budgetsCol(year: year, month: month)
          .doc(budgetId)
          .collection('expenses');

  // ── SharedPreferences helpers ─────────────────────────────────────────────

  Future<List<Budget>> _loadLocalBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyBudgets) ?? [])
        .map((s) => Budget.fromMap(json.decode(s)))
        .toList();
  }

  Future<void> _saveLocalBudgets(List<Budget> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyBudgets,
      budgets.map((b) => json.encode(b.toMap())).toList(),
    );
  }

  // Deleted budget IDs -------------------------------------------------------

  Future<Set<String>> _loadDeletedBudgetIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDeletedBudgetIds);
    if (raw == null) return {};
    return Set<String>.from(json.decode(raw) as List);
  }

  Future<void> _recordDeletedBudgetId(String budgetId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await _loadDeletedBudgetIds();
    ids.add(budgetId);
    await prefs.setString(_keyDeletedBudgetIds, json.encode(ids.toList()));
  }

  // Pending expense deletions ------------------------------------------------

  Future<Map<String, List<String>>> _loadPendingExpDeletions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingExpDeletions);
    if (raw == null) return {};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, List<String>.from(v as List)));
  }

  Future<void> _savePendingExpDeletions(Map<String, List<String>> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingExpDeletions, json.encode(map));
  }

  /// Records that [expenseId] under [budgetId] must be deleted from Firestore.
  /// Persists across cold restarts so offline deletions are never lost.
  Future<void> recordExpenseDeletion(String budgetId, String expenseId) async {
    final map = await _loadPendingExpDeletions();
    map.putIfAbsent(budgetId, () => []);
    if (!map[budgetId]!.contains(expenseId)) {
      map[budgetId]!.add(expenseId);
    }
    await _savePendingExpDeletions(map);
  }

  // ── Internal Firestore write helpers ──────────────────────────────────────

  /// Writes all budget fields (no expenses — those go in sub-collection).
  Future<void> _pushBudgetDoc(Budget budget, {int? year, int? month}) async {
    final data = budget.toMap()
      ..remove('expenses') // stored in sub-collection
      ..remove('isDirty'); // local-only flag
    await _budgetsCol(year: year, month: month)
        .doc(budget.id)
        .set(data, SetOptions(merge: true));
  }

  /// Upserts every expense in [budget.expenses] to Firestore.
  /// Pure write — never reads from Firestore, works offline.
  Future<void> _pushAllExpenses(Budget budget, {int? year, int? month}) async {
    final expCol = _expensesCol(budget.id, year: year, month: month);
    for (final expense in budget.expenses) {
      await expCol.doc(expense.id).set(expense.toMap(), SetOptions(merge: true));
    }
  }

  /// Replays pending expense deletions for [budgetId] to Firestore and removes
  /// them from the pending list on success.
  Future<void> _replayExpenseDeletions(String budgetId,
      {int? year, int? month}) async {
    final map = await _loadPendingExpDeletions();
    final pending = map[budgetId];
    if (pending == null || pending.isEmpty) return;

    final expCol = _expensesCol(budgetId, year: year, month: month);
    final remaining = <String>[];

    for (final expenseId in pending) {
      try {
        await expCol.doc(expenseId).delete();
      } catch (e) {
        remaining.add(expenseId); // keep for retry
        debugPrint('[BudgetSyncService] Could not delete expense $expenseId: $e');
      }
    }

    if (remaining.isEmpty) {
      map.remove(budgetId);
    } else {
      map[budgetId] = remaining;
    }
    await _savePendingExpDeletions(map);
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Pushes every dirty budget (and its expenses) to Firestore, then replays
  /// pending expense deletions.
  ///
  /// Write-only — never reads from Firestore, safe to call offline.
  /// isDirty stays true on failure so everything retries on the next call.
  Future<void> syncDirtyBudgets({int? year, int? month}) async {
    final budgets = await _loadLocalBudgets();
    bool anyChange = false;

    for (final budget in budgets) {
      if (!budget.isDirty) {
        // Still replay any outstanding expense deletions even for clean budgets.
        await _replayExpenseDeletions(budget.id, year: year, month: month);
        continue;
      }

      try {
        await _pushBudgetDoc(budget, year: year, month: month);
        await _pushAllExpenses(budget, year: year, month: month);
        await _replayExpenseDeletions(budget.id, year: year, month: month);

        budget.isDirty = false;
        anyChange = true;
        debugPrint('[BudgetSyncService] Synced: ${budget.name}');
      } catch (e) {
        debugPrint('[BudgetSyncService] Sync failed for "${budget.name}": $e');
        // isDirty stays true — retries on next call.
      }
    }

    if (anyChange) await _saveLocalBudgets(budgets);
  }

  /// Full two-way reconciliation between Firestore and SharedPreferences.
  ///
  /// Firestore is authoritative for WHICH budgets/expenses exist when online:
  ///
  ///   1. Local budgets missing from Firestore are REMOVED locally — UNLESS
  ///      they are dirty (created/edited offline), in which case they are kept
  ///      so syncDirtyBudgets() can push them when back online.
  ///
  ///   2. For synced (isDirty=false) budgets that exist in both places,
  ///      expenses are refreshed from Firestore so remote deletions/additions
  ///      are reflected locally.
  ///
  ///   3. Budgets in Firestore but missing locally are added to
  ///      SharedPreferences (reinstall / another device).
  ///
  ///   4. Budgets in the deleted-IDs list (deleted from the app UI) are
  ///      skipped so they are never re-added.
  ///
  /// If offline the Firestore fetch throws and SharedPreferences is left
  /// completely untouched — the app continues working from local data.
  Future<void> pullAndMerge({int? year, int? month}) async {
    try {
      final now = DateTime.now();
      final y = year ?? now.year;
      final m = month ?? now.month;

      // Fetch all budget docs for this month from Firestore.
      final snap = await _budgetsCol(year: y, month: m).get();
      final remoteIds = {for (final doc in snap.docs) doc.id};
      final deletedIds = await _loadDeletedBudgetIds();

      final localBudgets = await _loadLocalBudgets();
      final reconciled = <Budget>[];
      bool anyChange = false;

      // ── Step 1: walk existing local budgets ────────────────────────────
      for (final local in localBudgets) {
        if (remoteIds.contains(local.id)) {
          // Budget still exists in Firestore.
          if (!local.isDirty) {
            // Refresh expenses from Firestore — reflects remote deletions
            // or additions (e.g. done via console or another device).
            final expSnap =
                await _expensesCol(local.id, year: y, month: m).get();
            local.expenses
              ..clear()
              ..addAll(expSnap.docs.map((e) => Expense.fromMap(e.data())));
            anyChange = true;
          }
          // Dirty budgets keep their local expenses — syncDirtyBudgets
          // will overwrite Firestore with the local version next time.
          reconciled.add(local);
        } else {
          // Budget is NOT in Firestore.
          if (local.isDirty) {
            // Offline-created or offline-edited — keep locally.
            reconciled.add(local);
            debugPrint(
                '[BudgetSyncService] Keeping offline budget: ${local.name}');
          } else {
            // Synced budget that no longer exists in Firestore — deleted
            // remotely (console / another device). Remove locally too.
            anyChange = true;
            debugPrint(
                '[BudgetSyncService] Removing locally (deleted remotely): ${local.name}');
          }
        }
      }

      // ── Step 2: add budgets present in Firestore but missing locally ───
      final reconciledIds = {for (final b in reconciled) b.id};
      for (final doc in snap.docs) {
        if (deletedIds.contains(doc.id)) continue; // deleted from app UI
        if (reconciledIds.contains(doc.id)) continue; // already handled

        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;

        final expSnap = await _expensesCol(doc.id, year: y, month: m).get();
        data['expenses'] = expSnap.docs.map((e) => e.data()).toList();
        data['isDirty'] = false; // pulled from Firestore — already in sync

        reconciled.add(Budget.fromMap(data));
        anyChange = true;
        debugPrint(
            '[BudgetSyncService] Pulled new budget from Firestore: ${data['name']}');
      }

      if (anyChange) await _saveLocalBudgets(reconciled);
    } catch (e) {
      // Offline or network error — SharedPreferences left untouched.
      debugPrint('[BudgetSyncService] pullAndMerge error: $e');
    }
  }

  // ── Transaction helpers ───────────────────────────────────────────────────

  /// Returns the transactions collection reference for the given year/month.
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

  /// Creates a Firestore transaction document when a budget is finalized.
  ///
  /// Fields written:
  ///   type       — always "budget"
  ///   name       — budget name, e.g. "Groceries (Finalized)"
  ///   amount     — total spent across all expenses
  ///   refId      — budget.id  (used to find & delete this doc on unfinalize)
  ///   isLocked   — always true (budget transaction, cannot be edited freely)
  ///   createdAt  — server timestamp
  ///
  /// Returns the Firestore document ID so it can be stored on the budget if
  /// needed, or null if the write failed (offline).
  Future<String?> createFinalizeTransaction(
    Budget budget, {
    int? year,
    int? month,
  }) async {
    try {
      final ref = await _transactionsCol(year: year, month: month).add({
        'type': 'budget',
        'name': '${budget.name} (Finalized)',
        'amount': budget.totalSpent,
        'refId': budget.id,
        'isLocked': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
          '[BudgetSyncService] Finalize transaction created: ${ref.id}');
      return ref.id;
    } catch (e) {
      debugPrint(
          '[BudgetSyncService] createFinalizeTransaction error: $e');
      return null;
    }
  }

  /// Deletes the Firestore transaction document whose refId == [budgetId]
  /// and type == "budget". Called when a budget is unfinalized.
  ///
  /// Safe to call offline — the delete will simply fail silently. Because
  /// the budget's isChecked is already set to false locally and synced via
  /// syncDirtyBudgets, the UI will be correct. If the Firestore transaction
  /// doc is not deleted while offline, it will be a stale record; you may
  /// optionally track pending transaction deletions the same way expenses are
  /// tracked, but for most use-cases the next finalize cycle overwrites it.
  Future<void> deleteFinalizeTransaction(
    String budgetId, {
    int? year,
    int? month,
  }) async {
    try {
      final snap = await _transactionsCol(year: year, month: month)
          .where('refId', isEqualTo: budgetId)
          .where('type', isEqualTo: 'budget')
          .get();

      for (final doc in snap.docs) {
        await doc.reference.delete();
        debugPrint(
            '[BudgetSyncService] Finalize transaction deleted: ${doc.id}');
      }
    } catch (e) {
      debugPrint(
          '[BudgetSyncService] deleteFinalizeTransaction error: $e');
    }
  }

  /// Removes a budget from Firestore (and its expenses sub-collection) and
  /// records its ID so pullAndMerge() never re-adds it.
  Future<void> deleteBudgetRemote(Budget budget, {int? year, int? month}) async {
    // Record locally first — works offline and prevents re-import.
    await _recordDeletedBudgetId(budget.id);

    // Clear any pending expense deletions — not needed since the whole
    // budget is being deleted.
    final map = await _loadPendingExpDeletions();
    map.remove(budget.id);
    await _savePendingExpDeletions(map);

    try {
      // Delete expenses sub-collection.
      final expSnap =
          await _expensesCol(budget.id, year: year, month: month).get();
      for (final doc in expSnap.docs) {
        await doc.reference.delete();
      }

      // Delete the finalize transaction if the budget was finalized.
      if (budget.isChecked) {
        await deleteFinalizeTransaction(budget.id, year: year, month: month);
      }

      await _budgetsCol(year: year, month: month).doc(budget.id).delete();
      debugPrint('[BudgetSyncService] Deleted remote budget: ${budget.name}');
    } catch (e) {
      // Already in deleted-IDs list — won't come back via pullAndMerge.
      debugPrint('[BudgetSyncService] deleteBudgetRemote error: $e');
    }
  }
}