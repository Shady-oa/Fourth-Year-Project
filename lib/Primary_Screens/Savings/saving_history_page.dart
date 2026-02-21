import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Savings/saving_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavingHistoryPage extends StatefulWidget {
  final Saving saving;
  const SavingHistoryPage({super.key, required this.saving});

  @override
  State<SavingHistoryPage> createState() => _SavingHistoryPageState();
}

class _SavingHistoryPageState extends State<SavingHistoryPage> {
  late Saving _saving;

  static final _fmt = NumberFormat('#,##0', 'en_US');
  static String _ksh(double v) => 'Ksh ${_fmt.format(v.round())}';

  @override
  void initState() {
    super.initState();
    _saving = widget.saving;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [..._saving.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          _saving.name,
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

  Widget _header(BuildContext context, ThemeData theme) {
    final pct = _saving.progressPercent;
    final acColor = _saving.achieved ? brandGreen : accentColor;

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
                      _saving.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(achieved: _saving.achieved),
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
                  _ksh(_saving.savedAmount),
                  brandGreen,
                  theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  'Target',
                  _ksh(_saving.targetAmount),
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
        border: Border.all(
          color: isDeposit ? brandGreen.withOpacity(0.2) : Colors.grey.shade200,
        ),
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
