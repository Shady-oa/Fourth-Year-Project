import 'dart:async';
import 'dart:convert';

import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Primary_Screens/Savings/confirm_row.dart';
import 'package:final_project/Primary_Screens/Savings/financial_service.dart';
import 'package:final_project/Primary_Screens/Savings/saving_card.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:final_project/Primary_Screens/Savings/saving_options_sheet.dart';
import 'package:final_project/Primary_Screens/Savings/savings_confirm_sheet.dart';
import 'package:final_project/Primary_Screens/Savings/savings_empty_state.dart';
import 'package:final_project/Primary_Screens/Savings/savings_filter_chips.dart';
import 'package:final_project/Primary_Screens/Savings/savings_helpers.dart';
import 'package:final_project/Primary_Screens/Savings/savings_search_bar.dart';
import 'package:final_project/Primary_Screens/Savings/savings_summary_box.dart';
import 'package:final_project/Primary_Screens/Savings/savings_sync_service.dart';
import 'package:final_project/Primary_Screens/Savings/streak_banner.dart';
import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'saving_history_page.dart';

class SavingsPage extends StatefulWidget {
  final Function(String, double, String)? onTransactionAdded;
  const SavingsPage({super.key, this.onTransactionAdded});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  List<Saving> _savings = [];
  List<Saving> _filtered = [];
  String _filter = 'all';
  String _search = '';
  bool _isLoading = true;
  int _streakCount = 0;
  String _streakLevel = 'Base';
  final _searchCtrl = TextEditingController();

  late final SavingsSyncService _sync;

  @override
  void initState() {
    super.initState();
    _sync = SavingsSyncService(
      uid: FirebaseAuth.instance.currentUser!.uid,
    );
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── LOAD ──────────────────────────────────────────────────────────────────
  // Step 1 — read SharedPreferences and show the UI immediately (offline-safe).
  // Step 2 — sync with Firestore in the background (unawaited).

  Future<void> _load() async {
    setState(() => _isLoading = true);

    // ── Step 1: load from SharedPreferences — always instant. ───────────────
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(keySavings) ?? [];
    _savings = raw.map((s) => Saving.fromMap(json.decode(s))).toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    _streakCount = prefs.getInt(keyStreakCount) ?? 0;
    _streakLevel = prefs.getString(keyStreakLevel) ?? 'Base';

    await checkStreakExpiry(
      prefs,
      onReset: (count, level) {
        _streakCount = count;
        _streakLevel = level;
      },
      notify: (title, body) => savingsNotify(title, body),
    );

    _applyFilter();
    setState(() => _isLoading = false);

    // ── Step 2: sync with Firestore in the background. ─────────────────────
    unawaited(_syncInBackground());
  }

  Future<void> _syncInBackground() async {
    try {
      await _sync.syncDirtyGoals();
      await _sync.pullAndMerge();

      // Refresh UI with merged data.
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(keySavings) ?? [];
      if (!mounted) return;
      setState(() {
        _savings = raw.map((s) => Saving.fromMap(json.decode(s))).toList()
          ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        _applyFilter();
      });
    } catch (_) {
      // Offline — local data already shown, nothing to do.
    }
  }

  // ── PERSIST LOCAL ─────────────────────────────────────────────────────────
  // Saves to SharedPreferences (instant, offline-safe) then fires Firestore
  // sync in the background so the UI never waits on network.

  Future<void> _saveLocal() async {
    _savings.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      keySavings,
      _savings.map((s) => json.encode(s.toMap())).toList(),
    );
    // NOTE: Firestore sync is NOT triggered here.
    // _load() → _syncInBackground() is the single sync entry point,
    // preventing duplicate transaction writes.
  }

  void _applyFilter() {
    var list = _savings.where((s) {
      if (_filter == 'active') return !s.achieved;
      if (_filter == 'achieved') return s.achieved;
      return true;
    }).toList();
    if (_search.isNotEmpty) {
      list = list
          .where((s) => s.name.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    _filtered = list;
  }

  // ── CREATE GOAL ───────────────────────────────────────────────────────────
  Future<void> _createGoal() async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: brandGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.flag_outlined,
                          color: brandGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Savings Goal',
                            style: GoogleFonts.urbanist(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Set a target and deadline',
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Goal Name',
                      hintText: 'e.g. New Phone, Vacation',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Amount (Ksh)',
                      hintText: '0',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DatePickerTile(
                    selectedDate: selectedDate,
                    onDatePicked: (d) => setSt(() => selectedDate = d),
                    ctx: ctx,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandGreen,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            final target =
                                double.tryParse(targetCtrl.text) ?? 0;
                            if (nameCtrl.text.trim().isEmpty) {
                              AppToast.warning(context, 'Enter a goal name');
                              return;
                            }
                            if (target <= 0) {
                              AppToast.warning(
                                  context, 'Enter a valid target amount');
                              return;
                            }
                            final name = nameCtrl.text.trim();
                            final deadline = selectedDate;
                            Navigator.pop(ctx);
                            _showConfirm(
                              title: 'Confirm New Goal',
                              icon: Icons.flag_outlined,
                              iconColor: brandGreen,
                              rows: [
                                ConfirmRow('Goal Name', name),
                                ConfirmRow(
                                  'Target Amount',
                                  SavingsFmt.ksh(target),
                                  highlight: true,
                                ),
                                ConfirmRow(
                                  'Due Date',
                                  DateFormat('dd MMM yyyy').format(deadline),
                                ),
                              ],
                              confirmLabel: 'Create Goal',
                              confirmColor: brandGreen,
                              onConfirm: () async {
                                // New goal: isDirty=true by default so it
                                // syncs to Firestore when back online.
                                _savings.add(
                                  Saving(
                                    name: name,
                                    savedAmount: 0,
                                    targetAmount: target,
                                    deadline: deadline,
                                    isDirty: true,
                                  ),
                                );
                                // Save locally — instant, offline-safe.
                                await _saveLocal();
                                await savingsNotify(
                                  'New Goal Created',
                                  'Goal: $name — Target: ${SavingsFmt.ksh(target)}',
                                );
                                await _load();
                              },
                            );
                          },
                          child: const Text('Continue ›'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── ADD FUNDS ─────────────────────────────────────────────────────────────
  Future<void> _addFunds(Saving saving) async {
    final amountCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: brandGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.savings_outlined,
                        color: brandGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Funds',
                            style: GoogleFonts.urbanist(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Adding to: ${saving.name}',
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SavingsSummaryBox(saving: saving),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Amount to Add (Ksh)',
                    prefixIcon: Icon(Icons.add_circle_outline_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Transaction Cost (Ksh)',
                    hintText: '0',
                    prefixIcon: Icon(Icons.receipt_long_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final amount =
                              double.tryParse(amountCtrl.text) ?? 0;
                          final cost = double.tryParse(costCtrl.text) ?? 0;
                          if (amount <= 0) {
                            AppToast.warning(context, 'Enter a valid amount');
                            return;
                          }
                          if (cost < 0) {
                            AppToast.warning(
                                context, 'Transaction cost cannot be negative');
                            return;
                          }
                          final totalDeduct = amount + cost;
                          Navigator.pop(ctx);
                          _showConfirm(
                            title: 'Confirm Deposit',
                            icon: Icons.savings,
                            iconColor: brandGreen,
                            rows: [
                              ConfirmRow('Goal', saving.name),
                              ConfirmRow(
                                  'Amount Added', SavingsFmt.ksh(amount)),
                              if (cost > 0)
                                ConfirmRow(
                                    'Transaction Fee', SavingsFmt.ksh(cost)),
                              ConfirmRow(
                                'Total Deducted',
                                SavingsFmt.ksh(totalDeduct),
                                highlight: cost > 0,
                              ),
                            ],
                            note: cost > 0
                                ? 'Transaction fees are non-refundable.'
                                : null,
                            noteColor: Colors.orange,
                            confirmLabel: 'Confirm Deposit',
                            confirmColor: brandGreen,
                            onConfirm: () async {
                              final now = DateTime.now();

                              // 1. Update local model.
                              saving.savedAmount += amount;
                              saving.lastUpdated = now;
                              saving.isDirty = true;
                              saving.transactions.insert(
                                0,
                                SavingTransaction(
                                  type: 'deposit',
                                  amount: amount,
                                  transactionCost: cost,
                                  date: now,
                                  goalName: saving.name,
                                ),
                              );
                              final wasAchieved = saving.achieved;
                              if (saving.savedAmount >= saving.targetAmount &&
                                  !wasAchieved) {
                                saving.achieved = true;
                                await savingsNotify(
                                  'Goal Achieved! 🎉',
                                  'You reached ${saving.name}: ${SavingsFmt.ksh(saving.targetAmount)}!',
                                );
                              }

                              // 2. Log to global transactions in SharedPrefs.
                              await logGlobalTransaction(
                                'Saved for ${saving.name}',
                                totalDeduct,
                                'savings_deduction',
                                transactionCost: cost,
                                refId: saving.id,
                                reason: 'Deposit to savings goal',
                              );

                              // 3. Queue Firestore transaction write BEFORE
                              //    _saveLocal so the pending entry exists on
                              //    disk before any sync attempt runs.
                              await _sync.queueTransaction(
                                savingId: saving.id,
                                type: 'saving_deposit',
                                name: 'Saved for ${saving.name}',
                                amount: totalDeduct,
                                transactionCost: cost,
                                goalName: saving.name,
                                refId: saving.id,
                              );

                              // 4. Save to SharedPreferences — instant, offline-safe.
                              //    _load() below will trigger _syncInBackground()
                              //    which is the single path that replays pending
                              //    transactions to Firestore (prevents duplicates).
                              await _saveLocal();

                              widget.onTransactionAdded?.call(
                                'Saved for ${saving.name}',
                                totalDeduct,
                                'savings_deduction',
                              );

                              // 5. Update streak (writes to SharedPreferences).
                              final result =
                                  await updateStreak(_streakCount);
                              setState(() {
                                _streakCount = result.count;
                                _streakLevel = result.level;
                              });

                              // 6. Sync streak to Firestore in background.
                              unawaited(_sync.saveStreak(
                                count: result.count,
                                level: result.level,
                                lastSaveDate: DateFormat('yyyy-MM-dd')
                                    .format(now),
                              ));

                              if (result.count % 7 == 0) {
                                await savingsNotify(
                                  '🔥 Streak Milestone!',
                                  'Amazing! ${result.count} day streak at ${result.level} level!',
                                );
                              }

                              await _load();
                              if (mounted) {
                                AppToast.success(
                                  context,
                                  'Added ${SavingsFmt.ksh(amount)} · Deducted ${SavingsFmt.ksh(totalDeduct)}',
                                );
                              }
                            },
                          );
                        },
                        child: const Text('Continue ›'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── REMOVE FUNDS ──────────────────────────────────────────────────────────
  Future<void> _removeFunds(Saving saving) async {
    final amountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 8, bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.remove_circle_outline_rounded,
                        color: Colors.orange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Withdraw Funds',
                            style: GoogleFonts.urbanist(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'From: ${saving.name}',
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SavingsSummaryBox(saving: saving),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Amount to Withdraw (Ksh)',
                    helperText:
                        'Max: ${SavingsFmt.ksh(saving.savedAmount)}',
                    prefixIcon:
                        const Icon(Icons.remove_circle_outline_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final amount =
                              double.tryParse(amountCtrl.text) ?? 0;
                          if (amount <= 0) {
                            AppToast.warning(context, 'Enter a valid amount');
                            return;
                          }
                          if (amount > saving.savedAmount) {
                            AppToast.warning(
                              context,
                              'Cannot withdraw more than ${SavingsFmt.ksh(saving.savedAmount)}',
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          _showConfirm(
                            title: 'Confirm Withdrawal',
                            icon: Icons.remove_circle_outline,
                            iconColor: Colors.orange,
                            rows: [
                              ConfirmRow('Goal', saving.name),
                              ConfirmRow(
                                  'Withdraw Amount', SavingsFmt.ksh(amount)),
                              ConfirmRow(
                                'Remaining in Goal',
                                SavingsFmt.ksh(saving.savedAmount - amount),
                              ),
                            ],
                            note:
                                'Withdrawal restores the principal to your balance. Transaction fees already paid are non-refundable.',
                            noteColor: Colors.orange,
                            confirmLabel: 'Confirm Withdrawal',
                            confirmColor: Colors.orange,
                            onConfirm: () async {
                              final now = DateTime.now();

                              // 1. Update local model.
                              saving.savedAmount -= amount;
                              saving.lastUpdated = now;
                              saving.isDirty = true;
                              saving.transactions.insert(
                                0,
                                SavingTransaction(
                                  type: 'withdrawal',
                                  amount: amount,
                                  date: now,
                                  goalName: saving.name,
                                ),
                              );
                              if (saving.savedAmount < saving.targetAmount) {
                                saving.achieved = false;
                              }

                              // 2. Update global transactions in SharedPrefs.
                              await FinancialService.processWithdrawal(
                                goalName: saving.name,
                                withdrawAmount: amount,
                              );

                              // 3. Queue Firestore transaction write BEFORE
                              //    _saveLocal (same reason as deposits).
                              await _sync.queueTransaction(
                                savingId: saving.id,
                                type: 'savings_withdrawal',
                                name: 'Withdrawal from ${saving.name}',
                                amount: amount,
                                transactionCost: 0,
                                goalName: saving.name,
                                refId: saving.id,
                              );

                              // 4. Save locally — _load() triggers the single
                              //    sync path that replays the queued write.
                              await _saveLocal();

                              widget.onTransactionAdded?.call(
                                'Withdrawal from ${saving.name}',
                                amount,
                                'savings_withdrawal',
                              );

                              await _load();
                              if (mounted) {
                                AppToast.success(
                                  context,
                                  'Withdrew ${SavingsFmt.ksh(amount)} from ${saving.name}',
                                );
                              }
                            },
                          );
                        },
                        child: const Text('Continue ›'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── EDIT GOAL ─────────────────────────────────────────────────────────────
  Future<void> _editGoal(Saving saving) async {
    final nameCtrl = TextEditingController(text: saving.name);
    final targetCtrl = TextEditingController(
      text: saving.targetAmount.toStringAsFixed(0),
    );
    DateTime selectedDate = saving.deadline;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 8, bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: brandGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: brandGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Savings Goal',
                            style: GoogleFonts.urbanist(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Update goal details',
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Goal Name',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: targetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Amount (Ksh)',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DatePickerTile(
                    selectedDate: selectedDate,
                    onDatePicked: (d) => setSt(() => selectedDate = d),
                    ctx: ctx,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandGreen,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final target =
                                double.tryParse(targetCtrl.text) ?? 0;
                            if (nameCtrl.text.trim().isEmpty) {
                              AppToast.warning(context, 'Enter a goal name');
                              return;
                            }
                            if (target <= 0) {
                              AppToast.warning(
                                  context, 'Enter a valid target amount');
                              return;
                            }
                            saving.name = nameCtrl.text.trim();
                            saving.targetAmount = target;
                            saving.deadline = selectedDate;
                            saving.lastUpdated = DateTime.now();
                            saving.isDirty = true;
                            if (saving.savedAmount >= saving.targetAmount) {
                              if (!saving.achieved) {
                                saving.achieved = true;
                                await savingsNotify(
                                  'Goal Achieved!',
                                  'You reached ${saving.name}!',
                                );
                              }
                            } else {
                              saving.achieved = false;
                            }
                            await _saveLocal();
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _load();
                          },
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── DELETE GOAL ───────────────────────────────────────────────────────────
  Future<void> _deleteGoal(Saving saving) async {
    final isAchieved = saving.achieved;
    _showConfirm(
      title: 'Delete Savings Goal',
      icon: Icons.delete_outline,
      iconColor: errorColor,
      rows: [
        ConfirmRow('Goal', saving.name),
        ConfirmRow('Saved Amount', SavingsFmt.ksh(saving.savedAmount)),
      ],
      note: isAchieved
          ? 'This goal is achieved. Transaction history will be preserved. No refund will be made.'
          : saving.savedAmount > 0
              ? '${SavingsFmt.ksh(saving.savedAmount)} (saved principal) will be refunded to your balance. Transaction fees paid on deposits are non-refundable.'
              : 'This goal has no saved amount. It will simply be removed.',
      noteColor: isAchieved ? brandGreen : Colors.orange,
      confirmLabel: isAchieved ? 'Remove Goal' : 'Delete & Refund',
      confirmColor: errorColor,
      onConfirm: () async {
        if (isAchieved) {
          _savings.remove(saving);
          await _saveLocal();
          await savingsNotify(
            'Goal Removed',
            '${saving.name} (achieved) has been removed from your goals.',
          );
        } else {
          await FinancialService.refundSavingsPrincipal(
              goalName: saving.name);
          _savings.remove(saving);
          await _saveLocal();
          await savingsNotify(
            'Goal Deleted',
            saving.savedAmount > 0
                ? '${saving.name} deleted. ${SavingsFmt.ksh(saving.savedAmount)} refunded to balance.'
                : '${saving.name} deleted.',
          );
        }

        // Delete from Firestore in background — offline-safe.
        unawaited(_sync.deleteGoalRemote(saving));

        await _load();
        if (mounted) {
          AppToast.success(
            context,
            isAchieved ? 'Goal removed' : 'Goal deleted & refund applied',
          );
        }
      },
    );
  }

  // ── CONFIRM SHEET HELPER ──────────────────────────────────────────────────
  void _showConfirm({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<ConfirmRow> rows,
    String? note,
    Color noteColor = Colors.orange,
    required String confirmLabel,
    required Color confirmColor,
    required Future<void> Function() onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SavingsConfirmSheet(
        title: title,
        icon: icon,
        iconColor: iconColor,
        rows: rows,
        note: note,
        noteColor: noteColor,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
        onConfirm: onConfirm,
      ),
    );
  }

  // ── OPTIONS SHEET ─────────────────────────────────────────────────────────
  void _showOptions(Saving saving) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SavingOptionsSheet(
        saving: saving,
        onRemoveFunds: () => _removeFunds(saving),
        onEditGoal: () => _editGoal(saving),
        onDeleteGoal: () => _deleteGoal(saving),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const CustomHeader(headerName: 'Savings Goals'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                StreakBanner(
                  streakCount: _streakCount,
                  streakLevel: _streakLevel,
                ),
                SavingsSearchBar(
                  controller: _searchCtrl,
                  searchText: _search,
                  onChanged: (v) => setState(() {
                    _search = v;
                    _applyFilter();
                  }),
                  onClear: () => setState(() {
                    _searchCtrl.clear();
                    _search = '';
                    _applyFilter();
                  }),
                ),
                SavingsFilterChips(
                  currentFilter: _filter,
                  onFilterChanged: (v) => setState(() {
                    _filter = v;
                    _applyFilter();
                  }),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? SavingsEmptyState(
                          filter: _filter, search: _search)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: paddingAllMedium,
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => SavingCard(
                              saving: _filtered[i],
                              onAddFunds: () => _addFunds(_filtered[i]),
                              onShowOptions: () =>
                                  _showOptions(_filtered[i]),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SavingHistoryPage(
                                    saving: _filtered[i],
                                  ),
                                ),
                              ).then((_) => _load()),
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGoal,
        backgroundColor: brandGreen,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }
}

// ─── Reusable date picker tile ────────────────────────────────────────────────
class _DatePickerTile extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDatePicked;
  final BuildContext ctx;

  const _DatePickerTile({
    required this.selectedDate,
    required this.onDatePicked,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (picked != null) onDatePicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due Date',
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}