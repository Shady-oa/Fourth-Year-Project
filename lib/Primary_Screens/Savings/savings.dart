import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Models/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Formatter ─────────────────────────────────────────────────────────────
class _Fmt {
  static final _f = NumberFormat('#,##0', 'en_US');
  static String ksh(double v) => 'Ksh ${_f.format(v.round())}';
}

// ─── Streak level helper ────────────────────────────────────────────────────
String _levelFor(int n) {
  if (n == 0) return 'Base';
  if (n < 7) return 'Bronze';
  if (n < 30) return 'Silver';
  if (n < 90) return 'Gold';
  if (n < 180) return 'Platinum';
  return 'Diamond';
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SAVINGS PAGE — Real-time Firestore StreamBuilder
// ═══════════════════════════════════════════════════════════════════════════════
class SavingsPage extends StatefulWidget {
  final Function(String, double, String)? onTransactionAdded;
  const SavingsPage({super.key, this.onTransactionAdded});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  String _filter = 'all';
  String _search = '';
  final _searchCtrl = TextEditingController();

  // ── Firestore references ──────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _savingsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('savings');

  DocumentReference<Map<String, dynamic>> get _streakRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('metadata')
          .doc('streak');

  // ── Streak stream ─────────────────────────────────────────────────────────
  Stream<Map<String, dynamic>> get _streakStream =>
      _streakRef.snapshots().map((s) => s.data() ?? {});

  // ── Savings stream (filtered + searched) ─────────────────────────────────
  Stream<List<_SavingDoc>> _savingsStream() {
    return _savingsRef
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snap) {
      var list = snap.docs
          .map((d) => _SavingDoc(id: d.id, data: d.data()))
          .toList();

      // filter
      if (_filter == 'active') list = list.where((s) => !s.achieved).toList();
      if (_filter == 'achieved') list = list.where((s) => s.achieved).toList();

      // search
      if (_search.isNotEmpty) {
        list = list
            .where((s) =>
                s.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();
      }
      return list;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Notifications ─────────────────────────────────────────────────────────
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

  // ── Global transaction log (Firestore) ────────────────────────────────────
  Future<void> _logTransaction(
      String title, double amount, String type) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('transactions')
          .add({
        'title': title,
        'amount': amount,
        'type': type,
        'date': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ── Streak update ─────────────────────────────────────────────────────────
  Future<void> _updateStreak() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snap = await _streakRef.get();
    final data = snap.data() ?? {};
    final last = data['lastSaveDate'] ?? '';
    int count = data['count'] ?? 0;

    if (last == today) return;

    if (last.isNotEmpty) {
      final diff = DateTime.now()
          .difference(DateFormat('yyyy-MM-dd').parse(last))
          .inDays;
      count = diff == 1 ? count + 1 : 1;
    } else {
      count = 1;
    }

    final level = _levelFor(count);
    await _streakRef.set({
      'count': count,
      'level': level,
      'lastSaveDate': today,
    }, SetOptions(merge: true));

    if (count % 7 == 0) {
      await _notify(
        '🔥 Streak Milestone!',
        'Amazing! $count day streak at $level level!',
      );
    }
  }

  Future<void> _checkStreakExpiry() async {
    final snap = await _streakRef.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    final lastStr = data['lastSaveDate'] ?? '';
    if (lastStr.isEmpty) return;
    final diff = DateTime.now()
        .difference(DateFormat('yyyy-MM-dd').parse(lastStr))
        .inDays;
    if (diff >= 3) {
      await _streakRef.set({'count': 0, 'level': 'Base'}, SetOptions(merge: true));
      await _notify(
        '💔 Streak Lost',
        'Streak reset due to inactivity. Start saving again!',
      );
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _openCreateGoal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateGoalDialog(
        onSubmit: (name, target, deadline) async {
          // Duplicate check
          final existing =
              await _savingsRef.where('name', isEqualTo: name).limit(1).get();
          if (existing.docs.isNotEmpty) {
            _showSnack('A goal named "$name" already exists.', isError: true);
            return;
          }
          await _savingsRef.add({
            'name': name,
            'savedAmount': 0.0,
            'targetAmount': target,
            'deadline': deadline.toIso8601String(),
            'achieved': false,
            'transactions': [],
            'lastUpdated': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          await _notify(
            '🎯 New Goal Created',
            'Goal: $name — Target: ${_Fmt.ksh(target)}',
          );
          _showSnack('Goal "$name" created');
        },
      ),
    );
  }

  void _openAddFunds(_SavingDoc saving) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddFundsDialog(
        saving: saving,
        onSubmit: (amount, cost) async {
          final totalDeduct = amount + cost;
          final newSaved = saving.savedAmount + amount;
          final achieved = newSaved >= saving.targetAmount;

          final txList = List<Map<String, dynamic>>.from(
              saving.data['transactions'] ?? []);
          txList.insert(0, {
            'type': 'deposit',
            'amount': amount,
            'transactionCost': cost,
            'date': DateTime.now().toIso8601String(),
            'goalName': saving.name,
          });

          await _savingsRef.doc(saving.id).update({
            'savedAmount': newSaved,
            'achieved': achieved,
            'transactions': txList,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          if (achieved && !saving.achieved) {
            await _notify(
              '🎉 Goal Achieved!',
              'You reached ${saving.name}: ${_Fmt.ksh(saving.targetAmount)}!',
            );
          }

          await _logTransaction(
            'Saved for ${saving.name} (fee: ${_Fmt.ksh(cost)})',
            totalDeduct,
            'savings_deduction',
          );
          widget.onTransactionAdded?.call(
            'Saved for ${saving.name}',
            totalDeduct,
            'savings_deduction',
          );

          await _updateStreak();
          _showSnack(
              '✅ Added ${_Fmt.ksh(amount)} · Deducted ${_Fmt.ksh(totalDeduct)}');
        },
      ),
    );
  }

  void _openRemoveFunds(_SavingDoc saving) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RemoveFundsDialog(
        saving: saving,
        onSubmit: (amount) async {
          final newSaved = saving.savedAmount - amount;
          final achieved = newSaved >= saving.targetAmount;

          final txList = List<Map<String, dynamic>>.from(
              saving.data['transactions'] ?? []);
          txList.insert(0, {
            'type': 'withdrawal',
            'amount': amount,
            'transactionCost': 0.0,
            'date': DateTime.now().toIso8601String(),
            'goalName': saving.name,
          });

          await _savingsRef.doc(saving.id).update({
            'savedAmount': newSaved,
            'achieved': achieved,
            'transactions': txList,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          await _logTransaction(
            'Withdrawal from ${saving.name}',
            amount,
            'savings_withdrawal',
          );
          widget.onTransactionAdded?.call(
            'Withdrawal from ${saving.name}',
            amount,
            'savings_withdrawal',
          );

          _showSnack('✅ Withdrew ${_Fmt.ksh(amount)} from ${saving.name}');
        },
      ),
    );
  }

  void _openEditGoal(_SavingDoc saving) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditGoalDialog(
        saving: saving,
        onSubmit: (name, target, deadline) async {
          final achieved = saving.savedAmount >= target;
          await _savingsRef.doc(saving.id).update({
            'name': name,
            'targetAmount': target,
            'deadline': deadline.toIso8601String(),
            'achieved': achieved,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          if (achieved && !saving.achieved) {
            await _notify('🎉 Goal Achieved!', 'You reached $name!');
          }
          _showSnack('Goal updated');
        },
      ),
    );
  }

  Future<void> _deleteGoal(_SavingDoc saving) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete "${saving.name}"?'),
            if (saving.savedAmount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  '⚠️ ${_Fmt.ksh(saving.savedAmount)} saved will be returned to your balance.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _savingsRef.doc(saving.id).delete();
      await _notify('🗑️ Goal Deleted', '${saving.name} has been removed.');
      _showSnack('Goal deleted');
    }
  }

  void _showOptions(_SavingDoc saving) {
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.savings, color: brandGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      saving.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey.shade200, height: 24),
            _bsTile(ctx, Icons.remove_circle_outline, Colors.orange,
                'Remove Fund', 'Withdraw money from this goal',
                () => _openRemoveFunds(saving)),
            _bsTile(ctx, Icons.edit_outlined, Colors.blue, 'Edit Goal',
                'Modify name, target or deadline',
                () => _openEditGoal(saving)),
            _bsTile(ctx, Icons.delete_outline, errorColor, 'Delete Goal',
                'Permanently remove this goal', () => _deleteGoal(saving)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _bsTile(BuildContext ctx, IconData icon, Color color, String label,
      String sub, VoidCallback onTap) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title:
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sub,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? errorColor : brandGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Check streak expiry on mount (fire and forget)
    _checkStreakExpiry();

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: const CustomHeader(headerName: 'Savings Goals'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Streak banner ────────────────────────────────────────────────
          StreamBuilder<Map<String, dynamic>>(
            stream: _streakStream,
            builder: (_, snap) {
              final data = snap.data ?? {};
              final count = data['count'] as int? ?? 0;
              final level = data['level'] as String? ?? 'Base';
              return _buildStreak(count, level, theme);
            },
          ),
          _buildSearch(theme),
          _buildChips(theme),
          // ── Live list ────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<_SavingDoc>>(
              stream: _savingsStream(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Error loading savings.\nPlease try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }
                final list = snap.data ?? [];
                if (list.isEmpty) return _buildEmpty(theme);
                return ListView.builder(
                  padding: paddingAllMedium,
                  itemCount: list.length,
                  itemBuilder: (_, i) => _buildCard(list[i], theme),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateGoal,
        backgroundColor: brandGreen,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  // ── Streak banner ──────────────────────────────────────────────────────────
  Widget _buildStreak(int streakCount, String streakLevel, ThemeData theme) {
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
    final color = colors[streakLevel] ?? brandGreen;
    final emoji = emojis[streakLevel] ?? '🔥';

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
              offset: const Offset(0, 4))
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
            child:
                Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakCount Day${streakCount == 1 ? '' : 's'} Streak',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$streakLevel Saver',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (streakCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                streakCount > 99 ? '99+' : '$streakCount',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16),
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
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Search goals…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() {
                    _searchCtrl.clear();
                    _search = '';
                  }),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      onTap: () => setState(() => _filter = value),
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
          Text(msg,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(sub,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade400),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Saving card ────────────────────────────────────────────────────────────
  Widget _buildCard(_SavingDoc saving, ThemeData theme) {
    final daysLeft =
        DateTime.parse(saving.data['deadline']).difference(DateTime.now()).inDays;
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
        MaterialPageRoute(
            builder: (_) => SavingHistoryPage(savingDoc: saving)),
      ),
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
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
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
                                    fontWeight: FontWeight.bold, height: 1.2),
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
                            Icon(Icons.calendar_today_outlined,
                                size: 12, color: statusColor.withOpacity(0.8)),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(
                                  DateTime.parse(saving.data['deadline'])),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
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
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert,
                        size: 20, color: Colors.grey.shade500),
                    onPressed: () => _showOptions(saving),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            // Progress bar
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
                      Text('${(pct * 100).toStringAsFixed(0)}% saved',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                      Text('${_Fmt.ksh(saving.balance)} left',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Amounts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                      child: _amountBlock(
                          label: 'Saved',
                          amount: saving.savedAmount,
                          color: brandGreen,
                          theme: theme)),
                  Container(
                      width: 1, height: 36, color: Colors.grey.shade200),
                  Expanded(
                      child: _amountBlock(
                          label: 'Target',
                          amount: saving.targetAmount,
                          color: Colors.grey.shade700,
                          theme: theme,
                          alignRight: true)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Add Fund button or achieved banner
            if (!saving.achieved)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openAddFunds(saving),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Add Fund',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: brandGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.celebration_outlined,
                          size: 16, color: brandGreen),
                      const SizedBox(width: 6),
                      Text('Goal achieved! Great work 🎉',
                          style: TextStyle(
                              fontSize: 13,
                              color: brandGreen,
                              fontWeight: FontWeight.w600)),
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
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold)),
      );

  Widget _amountBlock({
    required String label,
    required double amount,
    required Color color,
    required ThemeData theme,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: alignRight ? 0 : 12,
            right: alignRight ? 12 : 0,
          ),
          child: Text(label,
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
                fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _SavingDoc — lightweight Firestore document wrapper
// ═══════════════════════════════════════════════════════════════════════════════
class _SavingDoc {
  final String id;
  final Map<String, dynamic> data;

  _SavingDoc({required this.id, required this.data});

  String get name => data['name'] ?? '';
  double get savedAmount => (data['savedAmount'] as num?)?.toDouble() ?? 0;
  double get targetAmount => (data['targetAmount'] as num?)?.toDouble() ?? 0;
  bool get achieved => data['achieved'] ?? false;
  double get balance => (targetAmount - savedAmount).clamp(0.0, double.infinity);
  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;

  List<Map<String, dynamic>> get transactions =>
      List<Map<String, dynamic>>.from(data['transactions'] ?? []);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CREATE GOAL DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
class _CreateGoalDialog extends StatefulWidget {
  final Future<void> Function(String name, double target, DateTime deadline)
      onSubmit;
  const _CreateGoalDialog({required this.onSubmit});

  @override
  State<_CreateGoalDialog> createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<_CreateGoalDialog> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text) ?? 0;
    if (name.isEmpty) {
      _snack('Enter a goal name', isError: true);
      return;
    }
    if (target <= 0) {
      _snack('Enter a valid target amount', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.onSubmit(name, target, _selectedDate);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? errorColor : brandGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: const Text('Create Savings Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                enabled: !_loading,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  hintText: 'e.g. New Phone, Vacation',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                enabled: !_loading,
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
                subtitle:
                    Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                trailing:
                    const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _loading
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setSt(() => _selectedDate = picked);
                          setState(() => _selectedDate = picked);
                        }
                      },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Create Goal'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EDIT GOAL DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
class _EditGoalDialog extends StatefulWidget {
  final _SavingDoc saving;
  final Future<void> Function(String name, double target, DateTime deadline)
      onSubmit;
  const _EditGoalDialog({required this.saving, required this.onSubmit});

  @override
  State<_EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<_EditGoalDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _targetCtrl;
  late DateTime _selectedDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.saving.name);
    _targetCtrl = TextEditingController(
        text: widget.saving.targetAmount.toStringAsFixed(0));
    _selectedDate = DateTime.parse(widget.saving.data['deadline']);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final target = double.tryParse(_targetCtrl.text) ?? 0;
    if (name.isEmpty) {
      _snack('Enter a goal name', isError: true);
      return;
    }
    if (target <= 0) {
      _snack('Enter a valid target amount', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.onSubmit(name, target, _selectedDate);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? errorColor : brandGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: const Text('Edit Savings Goal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                enabled: !_loading,
                decoration: const InputDecoration(
                  labelText: 'Goal Name',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                enabled: !_loading,
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
                subtitle:
                    Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                trailing:
                    const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _loading
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setSt(() => _selectedDate = picked);
                          setState(() => _selectedDate = picked);
                        }
                      },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ADD FUNDS DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
class _AddFundsDialog extends StatefulWidget {
  final _SavingDoc saving;
  final Future<void> Function(double amount, double cost) onSubmit;
  const _AddFundsDialog({required this.saving, required this.onSubmit});

  @override
  State<_AddFundsDialog> createState() => _AddFundsDialogState();
}

class _AddFundsDialogState extends State<_AddFundsDialog> {
  final _amountCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    final cost = double.tryParse(_costCtrl.text) ?? 0;
    if (amount <= 0) {
      _snack('Enter a valid amount', isError: true);
      return;
    }
    if (cost < 0) {
      _snack('Transaction cost cannot be negative', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.onSubmit(amount, cost);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? errorColor : brandGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _summaryBox() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: brandGreen.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            _sumRow('Saved', _Fmt.ksh(widget.saving.savedAmount)),
            const SizedBox(height: 4),
            _sumRow('Target', _Fmt.ksh(widget.saving.targetAmount)),
            const SizedBox(height: 4),
            _sumRow('Remaining', _Fmt.ksh(widget.saving.balance),
                valueColor: Colors.orange),
          ],
        ),
      );

  Widget _sumRow(String label, String value, {Color? valueColor}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Funds to ${widget.saving.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryBox(),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: 'Amount to Add (Ksh) *',
                prefixIcon: Icon(Icons.add_circle_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              enabled: !_loading,
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
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandGreen,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Add Funds'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  REMOVE FUNDS DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
class _RemoveFundsDialog extends StatefulWidget {
  final _SavingDoc saving;
  final Future<void> Function(double amount) onSubmit;
  const _RemoveFundsDialog({required this.saving, required this.onSubmit});

  @override
  State<_RemoveFundsDialog> createState() => _RemoveFundsDialogState();
}

class _RemoveFundsDialogState extends State<_RemoveFundsDialog> {
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      _snack('Enter a valid amount', isError: true);
      return;
    }
    if (amount > widget.saving.savedAmount) {
      _snack(
          'Cannot withdraw more than ${_Fmt.ksh(widget.saving.savedAmount)}',
          isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.onSubmit(amount);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? errorColor : brandGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Withdraw from ${widget.saving.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brandGreen.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Available', style: TextStyle(fontSize: 13)),
                Text(_Fmt.ksh(widget.saving.savedAmount),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            enabled: !_loading,
            decoration: InputDecoration(
              labelText: 'Amount to Withdraw (Ksh) *',
              helperText: 'Max: ${_Fmt.ksh(widget.saving.savedAmount)}',
              prefixIcon: const Icon(Icons.remove_circle_outline),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Withdraw'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SAVING HISTORY PAGE — reads from Firestore snapshot passed in via _SavingDoc
// ═══════════════════════════════════════════════════════════════════════════════
class SavingHistoryPage extends StatelessWidget {
  final _SavingDoc savingDoc;
  const SavingHistoryPage({super.key, required this.savingDoc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = savingDoc.transactions
      ..sort((a, b) =>
          DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    final pct = savingDoc.progressPercent;
    final acColor = savingDoc.achieved ? brandGreen : accentColor;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(savingDoc.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
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
                        child:
                            Icon(Icons.savings, color: acColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(savingDoc.name,
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            _StatusBadge(achieved: savingDoc.achieved),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _statCard('Saved',
                              _Fmt.ksh(savingDoc.savedAmount), brandGreen, theme)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard('Target',
                              _Fmt.ksh(savingDoc.targetAmount), Colors.grey.shade700, theme)),
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
                  Text('${(pct * 100).toStringAsFixed(0)}% of goal reached',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  Text('Transaction History',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          if (sorted.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No transactions yet',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: Colors.grey.shade500)),
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

  Widget _statCard(
          String label, String value, Color color, ThemeData theme) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      );

  Widget _txTile(Map<String, dynamic> tx, ThemeData theme) {
    final isDeposit = tx['type'] == 'deposit';
    final color = isDeposit ? brandGreen : Colors.orange;
    final icon = isDeposit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final sign = isDeposit ? '+' : '-';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final cost = (tx['transactionCost'] as num?)?.toDouble() ?? 0;
    final date = DateTime.parse(tx['date']);

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
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(isDeposit ? 'Deposit' : 'Withdrawal',
            style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd MMM yyyy, HH:mm').format(date),
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            if (isDeposit && cost > 0)
              Text('Fee: ${_Fmt.ksh(cost)}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.orange.shade600)),
          ],
        ),
        trailing: Text('$sign ${_Fmt.ksh(amount)}',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
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
          Icon(achieved ? Icons.check_circle : Icons.timelapse,
              size: 13, color: color),
          const SizedBox(width: 4),
          Text(achieved ? 'Achieved' : 'In Progress',
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}