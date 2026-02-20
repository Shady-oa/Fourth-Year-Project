import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Models/models.dart';
import 'package:final_project/Primary_Screens/Savings/financial_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fmt {
  static final _f = NumberFormat('#,##0', 'en_US');
  static String ksh(double v) => 'Ksh ${_f.format(v.round())}';
}

const _keySavings = 'savings';
const _keyTransactions = 'transactions';
const _keyTotalIncome = 'total_income';
const _keyStreakCount = 'streak_count';
const _keyLastSaveDate = 'last_save_date';
const _keyStreakLevel = 'streak_level';

class SavingsPage extends StatefulWidget {
  final Function(String, double, String)? onTransactionAdded;
  const SavingsPage({super.key, this.onTransactionAdded});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  List<Saving> _savings = [];
  List<Saving> _filtered = [];
  String _filter = 'all';
  String _search = '';
  bool _isLoading = true;
  int _streakCount = 0;
  String _streakLevel = 'Base';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keySavings) ?? [];
    _savings = raw.map((s) => Saving.fromMap(json.decode(s))).toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    _streakCount = prefs.getInt(_keyStreakCount) ?? 0;
    _streakLevel = prefs.getString(_keyStreakLevel) ?? 'Base';
    await _checkStreakExpiry(prefs);
    _applyFilter();
    setState(() => _isLoading = false);
  }

  Future<void> _sync() async {
    _savings.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keySavings,
      _savings.map((s) => json.encode(s.toMap())).toList(),
    );
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

  Future<void> _logGlobal(
    String title,
    double amount,
    String type, {
    double transactionCost = 0.0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTransactions) ?? '[]';
    final list = List<Map<String, dynamic>>.from(json.decode(raw));
    list.insert(0, {
      'title': title,
      'amount': amount,
      'transactionCost': transactionCost,
      'type': type,
      'date': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_keyTransactions, json.encode(list));
  }

  // _adjustIncome and _deleteRelatedTransactions removed.
  // Use FinancialService.processWithdrawal / FinancialService.refundSavingsPrincipal
  // so that all balance arithmetic is centralised in one place.

  Future<void> _checkStreakExpiry(SharedPreferences prefs) async {
    final lastStr = prefs.getString(_keyLastSaveDate) ?? '';
    if (lastStr.isEmpty) return;
    final diff = DateTime.now()
        .difference(DateFormat('yyyy-MM-dd').parse(lastStr))
        .inDays;
    if (diff >= 3) {
      _streakCount = 0;
      _streakLevel = 'Base';
      await prefs.setInt(_keyStreakCount, 0);
      await prefs.setString(_keyStreakLevel, 'Base');
      _notify(
        '💔 Streak Lost',
        'Streak reset due to inactivity. Start saving again!',
      );
    }
  }

  String _levelFor(int n) {
    if (n == 0) return 'Base';
    if (n < 7) return 'Bronze';
    if (n < 30) return 'Silver';
    if (n < 90) return 'Gold';
    if (n < 180) return 'Platinum';
    return 'Diamond';
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final last = prefs.getString(_keyLastSaveDate) ?? '';
    if (last == today) return;
    if (last.isNotEmpty) {
      final diff = DateTime.now()
          .difference(DateFormat('yyyy-MM-dd').parse(last))
          .inDays;
      _streakCount = diff == 1 ? _streakCount + 1 : 1;
    } else {
      _streakCount = 1;
    }
    _streakLevel = _levelFor(_streakCount);
    final prefs2 = await SharedPreferences.getInstance();
    await prefs2.setInt(_keyStreakCount, _streakCount);
    await prefs2.setString(_keyStreakLevel, _streakLevel);
    await prefs2.setString(_keyLastSaveDate, today);
    if (_streakCount % 7 == 0) {
      _notify(
        '🔥 Streak Milestone!',
        'Amazing! $_streakCount day streak at $_streakLevel level!',
      );
    }
  }

  Future<void> _notify(String title, String body) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .add({
            'title': title,
            'message': body,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
    } catch (_) {}
  }

  // ── CREATE GOAL ────────────────────────────────────────────────────────────
  Future<void> _createGoal() async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Create Savings Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    hintText: 'e.g. New Phone, Vacation',
                    prefixIcon: Icon(Icons.edit),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (Ksh)',
                    hintText: '0',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Due Date'),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setSt(() => selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                final target = double.tryParse(targetCtrl.text) ?? 0;
                if (nameCtrl.text.trim().isEmpty) {
                  _snack('Enter a goal name', isError: true);
                  return;
                }
                if (target <= 0) {
                  _snack('Enter a valid target amount', isError: true);
                  return;
                }
                _savings.add(
                  Saving(
                    name: nameCtrl.text.trim(),
                    savedAmount: 0,
                    targetAmount: target,
                    deadline: selectedDate,
                  ),
                );
                await _sync();
                await _notify(
                  '🎯 New Goal Created',
                  'Goal: ${nameCtrl.text} — Target: ${_Fmt.ksh(target)}',
                );
                if (mounted) Navigator.pop(ctx);
                await _load();
              },
              child: const Text('Create Goal'),
            ),
          ],
        ),
      ),
    );
  }

  // ── ADD FUNDS ──────────────────────────────────────────────────────────────
  Future<void> _addFunds(Saving saving) async {
    final amountCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Funds to ${saving.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _summaryBox(saving),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Amount to Add (Ksh) *',
                  prefixIcon: Icon(Icons.add_circle_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Transaction Cost (Ksh) *',
                  hintText: '0',
                  prefixIcon: Icon(Icons.receipt_long),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              final cost = double.tryParse(costCtrl.text) ?? 0;
              if (amount <= 0) {
                _snack('Enter a valid amount', isError: true);
                return;
              }
              if (cost < 0) {
                _snack('Transaction cost cannot be negative', isError: true);
                return;
              }

              final totalDeduct = amount + cost;
              saving.savedAmount += amount;
              saving.lastUpdated = DateTime.now();
              saving.transactions.insert(
                0,
                SavingTransaction(
                  type: 'deposit',
                  amount: amount,
                  transactionCost: cost,
                  date: DateTime.now(),
                  goalName: saving.name,
                ),
              );

              final wasAchieved = saving.achieved;
              if (saving.savedAmount >= saving.targetAmount && !wasAchieved) {
                saving.achieved = true;
                await _notify(
                  '🎉 Goal Achieved!',
                  'You reached ${saving.name}: ${_Fmt.ksh(saving.targetAmount)}!',
                );
              }

              await _sync();
              await _logGlobal(
                'Saved for ${saving.name}',
                totalDeduct,
                'savings_deduction',
                transactionCost: cost,
              );
              widget.onTransactionAdded?.call(
                'Saved for ${saving.name}',
                totalDeduct,
                'savings_deduction',
              );
              await _updateStreak();
              if (mounted) Navigator.pop(ctx);
              await _load();
              if (mounted) {
                _snack(
                  '✅ Added ${_Fmt.ksh(amount)} · Deducted ${_Fmt.ksh(totalDeduct)}',
                );
              }
            },
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }

  // ── REMOVE FUNDS ───────────────────────────────────────────────────────────
  //
  //  Withdrawal logic (CORRECT — no income mutation):
  //  ─────────────────────────────────────────────────
  //  1. Reduce saving.savedAmount by the withdrawn amount.
  //  2. Call FinancialService.processWithdrawal which:
  //       a. Removes matching savings_deduction rows (FIFO newest-first) until
  //          the withdrawn principal is accounted for.
  //       b. Re-logs any fees from removed rows as permanent non-refundable
  //          expenses (so fees are never silently refunded).
  //       c. Appends a display-only 'savings_withdrawal' record.
  //  3. _compute() skips 'savings_withdrawal' → balance rises automatically
  //     because the deduction rows are gone, without touching total_income.
  Future<void> _removeFunds(Saving saving) async {
    final amountCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Withdraw from ${saving.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryBox(saving),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Amount to Withdraw (Ksh) *',
                helperText: 'Max: ${_Fmt.ksh(saving.savedAmount)}',
                prefixIcon: const Icon(Icons.remove_circle_outline),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) {
                _snack('Enter a valid amount', isError: true);
                return;
              }
              if (amount > saving.savedAmount) {
                _snack(
                  'Cannot withdraw more than ${_Fmt.ksh(saving.savedAmount)}',
                  isError: true,
                );
                return;
              }

              // 1. Update local savings object
              saving.savedAmount -= amount;
              saving.lastUpdated = DateTime.now();
              saving.transactions.insert(
                0,
                SavingTransaction(
                  type: 'withdrawal',
                  amount: amount,
                  date: DateTime.now(),
                  goalName: saving.name,
                ),
              );
              if (saving.savedAmount < saving.targetAmount) {
                saving.achieved = false;
              }

              await _sync();

              // 2. Use FinancialService to correctly remove deduction rows
              //    and add a display-only withdrawal record.
              //    total_income is NEVER modified.
              await FinancialService.processWithdrawal(
                goalName: saving.name,
                withdrawAmount: amount,
              );

              // 3. Notify parent so Home Page refreshes its balance card
              widget.onTransactionAdded?.call(
                'Withdrawal from ${saving.name}',
                amount,
                'savings_withdrawal',
              );

              if (mounted) Navigator.pop(ctx);
              await _load();
              if (mounted) {
                _snack('✅ Withdrew ${_Fmt.ksh(amount)} from ${saving.name}');
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  // ── EDIT GOAL ──────────────────────────────────────────────────────────────
  Future<void> _editGoal(Saving saving) async {
    final nameCtrl = TextEditingController(text: saving.name);
    final targetCtrl = TextEditingController(
      text: saving.targetAmount.toStringAsFixed(0),
    );
    DateTime selectedDate = saving.deadline;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Edit Savings Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    prefixIcon: Icon(Icons.edit),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (Ksh)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Due Date'),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setSt(() => selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                final target = double.tryParse(targetCtrl.text) ?? 0;
                if (nameCtrl.text.trim().isEmpty) {
                  _snack('Enter a goal name', isError: true);
                  return;
                }
                if (target <= 0) {
                  _snack('Enter a valid target amount', isError: true);
                  return;
                }

                saving.name = nameCtrl.text.trim();
                saving.targetAmount = target;
                saving.deadline = selectedDate;
                saving.lastUpdated = DateTime.now();

                if (saving.savedAmount >= saving.targetAmount) {
                  if (!saving.achieved) {
                    saving.achieved = true;
                    await _notify(
                      '🎉 Goal Achieved!',
                      'You reached ${saving.name}!',
                    );
                  }
                } else {
                  saving.achieved = false;
                }

                await _sync();
                if (mounted) Navigator.pop(ctx);
                await _load();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DELETE GOAL — UPDATED LOGIC
  //
  //  ✅ Achieved goal deleted:
  //    - Remove from savings list only.
  //    - Do NOT refund balance.
  //    - Do NOT delete existing transactions (keep financial history intact).
  //
  //  ✅ Unachieved goal deleted:
  //    - Refund savedAmount to income balance.
  //    - Delete all related savings_deduction / saving_deposit transactions.
  //    - Log a refund transaction for transparency.
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _deleteGoal(Saving saving) async {
    final isAchieved = saving.achieved;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete "${saving.name}"?'),
            const SizedBox(height: 12),
            if (isAchieved)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: brandGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: brandGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This goal is achieved. Transaction history will be preserved. No refund will be made.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ ${_Fmt.ksh(saving.savedAmount)} (saved principal) will be refunded to your balance.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Transaction fees paid on deposits are non-refundable.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (saving.savedAmount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'All related saving transactions will also be removed.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (isAchieved) {
        // ── Achieved goal: just remove from list, no refund, keep transactions
        _savings.remove(saving);
        await _sync();
        await _notify(
          '🗑️ Goal Removed',
          '${saving.name} (achieved) has been removed from your goals.',
        );
      } else {
        // ── Unachieved goal: restore balance through transaction-list surgery.
        //
        //    MATH (balance = totalIncome − totalExpenses):
        //    ─────────────────────────────────────────────────────────────────
        //    Each deposit was logged as a 'savings_deduction' with
        //      amount = savedPrincipal + fee  (e.g. 105 for 100 + 5 deposit)
        //
        //    Step 1 – _deleteRelatedTransactions removes those entries
        //             → totalExpenses drops by (savedAmount + totalFeesPaid)
        //    Step 2 – Re-log fees as a permanent 'expense'
        //             → totalExpenses rises back by totalFeesPaid
        //    Net    – totalExpenses drops by savedAmount
        //             balance increases by savedAmount  ✓
        //             totalIncome is NEVER changed       ✓
        //    ─────────────────────────────────────────────────────────────────

        // Collect total fees from this goal's deposit history
        final totalFeesPaid = saving.transactions
            .where((t) => t.type == 'deposit')
            .fold(0.0, (s, t) => s + t.transactionCost);

        // Centralised service handles:
        //   1. Remove savings_deduction / saving_deposit rows for this goal
        //   2. Re-log fees as a permanent non-refundable 'expense'
        // Net: expenses drop by savedPrincipal; balance rises accordingly.
        // total_income is NEVER modified.
        await FinancialService.refundSavingsPrincipal(
          goalName: saving.name,
          totalFeesPaid: totalFeesPaid,
        );

        _savings.remove(saving);
        await _sync();
        await _notify(
          '🗑️ Goal Deleted',
          saving.savedAmount > 0
              ? '${saving.name} deleted. ${_Fmt.ksh(saving.savedAmount)} refunded to balance.'
              : '${saving.name} deleted.',
        );
      }

      await _load();
      if (mounted) {
        _snack(isAchieved ? 'Goal removed' : 'Goal deleted & refund applied');
      }
    }
  }

  void _showOptions(Saving saving) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.savings,
                      color: brandGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      saving.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade200, height: 24),
            _bsTile(
              ctx,
              Icons.remove_circle_outline,
              Colors.orange,
              'Remove Fund',
              'Withdraw money from this goal',
              () => _removeFunds(saving),
            ),
            _bsTile(
              ctx,
              Icons.edit_outlined,
              Colors.blue,
              'Edit Goal',
              'Modify name, target or deadline',
              () => _editGoal(saving),
            ),
            _bsTile(
              ctx,
              Icons.delete_outline,
              errorColor,
              'Delete Goal',
              'Permanently remove this goal',
              () => _deleteGoal(saving),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _bsTile(
    BuildContext ctx,
    IconData icon,
    Color color,
    String label,
    String sub,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        sub,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? errorColor : brandGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
                _buildStreak(theme),
                _buildSearch(theme),
                _buildChips(theme),
                Expanded(
                  child: _filtered.isEmpty
                      ? _buildEmpty(theme)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: paddingAllMedium,
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) =>
                                _buildCard(_filtered[i], theme),
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

  Widget _buildStreak(ThemeData theme) {
    const colors = {
      'Base': Color(0xFF6C757D),
      'Bronze': Color(0xFFCD7F32),
      'Silver': Color(0xFF9E9E9E),
      'Gold': Color(0xFFFFC107),
      'Platinum': Color(0xFF00BCD4),
      'Diamond': Color(0xFF7C4DFF),
    };
    const emojis = {
      'Base': '🔥',
      'Bronze': '🥉',
      'Silver': '🥈',
      'Gold': '🥇',
      'Platinum': '💎',
      'Diamond': '💠',
    };
    final color = colors[_streakLevel] ?? brandGreen;
    final emoji = emojis[_streakLevel] ?? '🔥';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_streakCount Day${_streakCount == 1 ? '' : 's'} Streak',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_streakLevel Saver',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (_streakCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _streakCount > 99 ? '99+' : '$_streakCount',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearch(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() {
          _search = v;
          _applyFilter();
        }),
        decoration: InputDecoration(
          hintText: 'Search goals…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    _searchCtrl.clear();
                    _search = '';
                    _applyFilter();
                  }),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildChips(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _chip('All', 'all', theme),
          const SizedBox(width: 8),
          _chip('Active', 'active', theme),
          const SizedBox(width: 8),
          _chip('Achieved', 'achieved', theme),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, ThemeData theme) {
    final sel = _filter == value;
    return GestureDetector(
      onTap: () => setState(() {
        _filter = value;
        _applyFilter();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? brandGreen : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? brandGreen : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: sel ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    final msg = _search.isNotEmpty
        ? 'No results for "$_search"'
        : _filter == 'active'
        ? 'No active goals'
        : _filter == 'achieved'
        ? 'No achieved goals yet'
        : 'No savings goals yet';
    final sub = _search.isNotEmpty
        ? 'Try a different search'
        : _filter == 'active'
        ? 'All goals achieved! Create a new one.'
        : _filter == 'achieved'
        ? 'Keep saving to reach your goals!'
        : 'Tap + New Goal to get started';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            msg,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Saving saving, ThemeData theme) {
    final daysLeft = saving.deadline.difference(DateTime.now()).inDays;
    final overdue = daysLeft < 0;
    final urgent = !overdue && daysLeft <= 7;
    final pct = saving.progressPercent;

    Color statusColor;
    if (saving.achieved) {
      statusColor = brandGreen;
    } else if (overdue) {
      statusColor = errorColor;
    } else if (urgent) {
      statusColor = Colors.orange;
    } else {
      statusColor = accentColor;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SavingHistoryPage(saving: saving)),
      ).then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: saving.achieved
                ? brandGreen.withOpacity(0.45)
                : overdue
                ? errorColor.withOpacity(0.35)
                : Colors.grey.shade200,
            width: saving.achieved ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.savings, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                saving.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (saving.achieved)
                              _statusBadge('✓ Achieved', brandGreen)
                            else if (overdue)
                              _statusBadge('Overdue', errorColor)
                            else if (urgent)
                              _statusBadge('Due soon', Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: statusColor.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(saving.deadline),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                saving.achieved
                                    ? 'Goal met!'
                                    : overdue
                                    ? '${daysLeft.abs()}d overdue'
                                    : '$daysLeft days left',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () => _showOptions(saving),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}% saved',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        '${_Fmt.ksh(saving.balance)} left',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _amountBlock(
                      label: 'Saved',
                      amount: saving.savedAmount,
                      color: brandGreen,
                      theme: theme,
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.grey.shade200),
                  Expanded(
                    child: _amountBlock(
                      label: 'Target',
                      amount: saving.targetAmount,
                      color: Colors.grey.shade700,
                      theme: theme,
                      alignRight: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (!saving.achieved)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _addFunds(saving),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text(
                      'Add Fund',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: brandGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.celebration_outlined,
                        size: 16,
                        color: brandGreen,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Goal achieved! Great work 🎉',
                        style: TextStyle(
                          fontSize: 13,
                          color: brandGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );

  Widget _amountBlock({
    required String label,
    required double amount,
    required Color color,
    required ThemeData theme,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: alignRight ? 0 : 12,
            right: alignRight ? 12 : 0,
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ),
        const SizedBox(height: 3),
        Padding(
          padding: EdgeInsets.only(
            left: alignRight ? 0 : 12,
            right: alignRight ? 12 : 0,
          ),
          child: Text(
            _Fmt.ksh(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryBox(Saving saving) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: brandGreen.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        _sumRow('Saved', _Fmt.ksh(saving.savedAmount)),
        const SizedBox(height: 4),
        _sumRow('Target', _Fmt.ksh(saving.targetAmount)),
        const SizedBox(height: 4),
        _sumRow(
          'Remaining',
          _Fmt.ksh(saving.balance),
          valueColor: Colors.orange,
        ),
      ],
    ),
  );

  Widget _sumRow(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13)),
      Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: valueColor,
        ),
      ),
    ],
  );
}

// ─── Saving History Screen (unchanged) ───────────────────────────────────────
class SavingHistoryPage extends StatelessWidget {
  final Saving saving;
  const SavingHistoryPage({super.key, required this.saving});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [...saving.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          saving.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header(context, theme)),
          if (sorted.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'No transactions yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _txTile(sorted[i], theme),
                  childCount: sorted.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static final _fmt = NumberFormat('#,##0', 'en_US');
  static String _ksh(double v) => 'Ksh ${_fmt.format(v.round())}';

  Widget _header(BuildContext context, ThemeData theme) {
    final pct = saving.progressPercent;
    final acColor = saving.achieved ? brandGreen : accentColor;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: acColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: acColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: acColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.savings, color: acColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saving.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(achieved: saving.achieved),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Saved',
                  _ksh(saving.savedAmount),
                  brandGreen,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Target',
                  _ksh(saving.targetAmount),
                  Colors.grey.shade700,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(acColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).toStringAsFixed(0)}% of goal reached',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          Text(
            'Transaction History',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, ThemeData theme) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );

  Widget _txTile(SavingTransaction tx, ThemeData theme) {
    final isDeposit = tx.type == 'deposit';
    final color = isDeposit ? brandGreen : Colors.orange;
    final icon = isDeposit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final sign = isDeposit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          isDeposit ? 'Deposit' : 'Withdrawal',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(tx.date),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            if (isDeposit && tx.transactionCost > 0)
              Text(
                'Fee: ${_ksh(tx.transactionCost)}',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade600),
              ),
          ],
        ),
        trailing: Text(
          '$sign ${_ksh(tx.amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool achieved;
  const _StatusBadge({required this.achieved});

  @override
  Widget build(BuildContext context) {
    final color = achieved ? brandGreen : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            achieved ? Icons.check_circle : Icons.timelapse,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            achieved ? 'Achieved' : 'In Progress',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
