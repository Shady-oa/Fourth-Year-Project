import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Notification Type ────────────────────────────────────────────────────────
enum _NotifType { budget, savings, streak, analysis, report, insight, system }

extension _NotifTypeX on _NotifType {
  // The canonical string stored in Firestore for each type
  String get firestoreValue {
    switch (this) {
      case _NotifType.budget:
        return 'budget';
      case _NotifType.savings:
        return 'savings';
      case _NotifType.streak:
        return 'streak';
      case _NotifType.analysis:
        return 'analysis';
      case _NotifType.report:
        return 'report';
      case _NotifType.insight:
        return 'insight';
      case _NotifType.system:
        return 'system';
    }
  }

  static _NotifType fromString(String? v) {
    switch (v) {
      case 'budget':
        return _NotifType.budget;
      case 'savings':
        return _NotifType.savings;
      case 'streak':
        return _NotifType.streak;
      case 'analysis':
        return _NotifType.analysis;
      case 'report':
        return _NotifType.report;
      case 'insight':
        return _NotifType.insight;
      default:
        return _NotifType.system;
    }
  }

  IconData get icon {
    switch (this) {
      case _NotifType.budget:
        return Icons.account_balance_wallet_outlined;
      case _NotifType.savings:
        return Icons.savings_outlined;
      case _NotifType.streak:
        return Icons.local_fire_department_outlined;
      case _NotifType.analysis:
        return Icons.bar_chart_rounded;
      case _NotifType.report:
        return Icons.summarize_outlined;
      case _NotifType.insight:
        return Icons.lightbulb_outline;
      case _NotifType.system:
        return Icons.notifications_outlined;
    }
  }

  Color get color {
    switch (this) {
      case _NotifType.budget:
        return const Color(0xFF6C63FF);
      case _NotifType.savings:
        return const Color(0xFF00B894);
      case _NotifType.streak:
        return const Color(0xFFE17055);
      case _NotifType.analysis:
        return const Color(0xFF0984E3);
      case _NotifType.report:
        return const Color(0xFF6C5CE7);
      case _NotifType.insight:
        return const Color(0xFFFDAA40);
      case _NotifType.system:
        return const Color(0xFF636E72);
    }
  }

  String get label {
    switch (this) {
      case _NotifType.budget:
        return 'Budget';
      case _NotifType.savings:
        return 'Savings';
      case _NotifType.streak:
        return 'Streak';
      case _NotifType.analysis:
        return 'Analysis';
      case _NotifType.report:
        return 'Reports';
      case _NotifType.insight:
        return 'Insights';
      case _NotifType.system:
        return 'System';
    }
  }
}

const _kAllFilter = 'all';

const _filters = [
  _kAllFilter,
  'budget',
  'savings',
  'streak',
  'insight',
  'analysis',
  'report',
  'system',
];

// ─── Notifications Page ───────────────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  final String userId;
  const NotificationsPage({super.key, required this.userId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  String _activeFilter = _kAllFilter;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _markAllAsRead();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Firestore reference ───────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(widget.userId)
      .collection('notifications');

  // ── Actions ───────────────────────────────────────────────────────────────────
  Future<void> _markAllAsRead() async {
    try {
      final unread = await _col.where('isRead', isEqualTo: false).get();
      if (unread.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  Future<void> _markSingleRead(QueryDocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data?['isRead'] == true) return;
      await doc.reference.update({'isRead': true});
    } catch (_) {}
  }

  Future<void> _deleteDoc(DocumentSnapshot doc) async {
    try {
      await doc.reference.delete();
    } catch (_) {}
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Notifications'),
        content: const Text('This will permanently delete all notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final all = await _col.get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in all.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  /// Read raw 'type' string directly from Firestore document data.
  /// This is the KEY FIX — compare the raw string, not the enum, so we never
  /// lose information through a fromString() round-trip.
  String _rawTypeOf(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    // If 'type' field is missing (old docs), treat as 'system'
    return (data?['type'] as String?) ?? 'system';
  }

  /// Convert raw type string → _NotifType for display (icon, colour, label)
  _NotifType _notifTypeOf(QueryDocumentSnapshot doc) =>
      _NotifTypeX.fromString(_rawTypeOf(doc));

  bool _isRead(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return data?['isRead'] as bool? ?? false;
  }

  String _dateLabel(Timestamp ts) {
    final d = ts.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';
    if (today.difference(day).inDays < 7) return DateFormat('EEEE').format(d);
    return DateFormat('dd MMM yyyy').format(d);
  }

  String _timeStr(Timestamp ts) => DateFormat('HH:mm').format(ts.toDate());

  /// THE FIX: Compare _activeFilter directly against the raw Firestore
  /// 'type' string — no enum conversion in the middle that could silently
  /// map an unknown value to 'system' and break the filter.
  List<QueryDocumentSnapshot> _applyFilter(List<QueryDocumentSnapshot> docs) {
    if (_activeFilter == _kAllFilter) return docs;
    return docs.where((doc) => _rawTypeOf(doc) == _activeFilter).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildFilterBar(theme),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Notifications',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        // Mark-all-read — visible only when unread notifications exist
        StreamBuilder<QuerySnapshot>(
          stream: _col.where('isRead', isEqualTo: false).snapshots(),
          builder: (ctx, snap) {
            if (!(snap.data?.docs.isNotEmpty ?? false)) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all_rounded),
              onPressed: _markAllAsRead,
            );
          },
        ),
        IconButton(
          tooltip: 'Clear all',
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: _deleteAll,
        ),
      ],
    );
  }

  // ── Filter chip bar ───────────────────────────────────────────────────────────
  Widget _buildFilterBar(ThemeData theme) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final f = _filters[i];
          final isSelected = _activeFilter == f;
          final notifType = _NotifTypeX.fromString(f);
          final label = f == _kAllFilter ? 'All' : notifType.label;
          final color = f == _kAllFilter
              ? theme.colorScheme.primary
              : notifType.color;

          return GestureDetector(
            onTap: () {
              setState(() {
                _activeFilter = f; // store the raw filter string
                _fadeCtrl
                  ..reset()
                  ..forward();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Body (StreamBuilder) ──────────────────────────────────────────────────────
  Widget _buildBody(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      // Single-field orderBy only — no composite index required
      stream: _col.orderBy('createdAt', descending: true).snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorState(theme);
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(theme);
        }

        final allDocs = snapshot.data!.docs;

        // Client-side filter using raw Firestore 'type' string comparison
        final filtered = _applyFilter(allDocs);
        if (filtered.isEmpty) return _buildEmptyState(theme);

        // Count unread across ALL docs (regardless of active filter)
        final unreadCount = allDocs.where((d) => !_isRead(d)).length;

        // Group filtered docs by human-readable date label
        final grouped = <String, List<QueryDocumentSnapshot>>{};
        for (final doc in filtered) {
          final data = doc.data() as Map<String, dynamic>?;
          final ts = data?['createdAt'] as Timestamp?;
          if (ts == null) continue;
          grouped.putIfAbsent(_dateLabel(ts), () => []).add(doc);
        }

        if (grouped.isEmpty) return _buildEmptyState(theme);

        return FadeTransition(
          opacity: _fadeCtrl,
          child: Column(
            children: [
              if (unreadCount > 0) _buildUnreadBanner(theme, unreadCount),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: grouped.length,
                  itemBuilder: (ctx, i) {
                    final label = grouped.keys.elementAt(i);
                    return _buildDateGroup(theme, label, grouped[label]!);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Unread banner ─────────────────────────────────────────────────────────────
  Widget _buildUnreadBanner(ThemeData theme, int count) {
    return GestureDetector(
      onTap: _markAllAsRead,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count unread notification${count == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Text(
              'Mark all read',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ── Date group ────────────────────────────────────────────────────────────────
  Widget _buildDateGroup(
    ThemeData theme,
    String dateLabel,
    List<QueryDocumentSnapshot> docs,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
          child: Row(
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withOpacity(0.35)
                      : Colors.black.withOpacity(0.3),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Divider(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.06),
                  thickness: 1,
                ),
              ),
            ],
          ),
        ),
        ...docs.map((doc) => _buildCard(theme, doc)),
      ],
    );
  }

  // ── Notification card — bold new look ────────────────────────────────────────
  Widget _buildCard(ThemeData theme, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final isRead = data['isRead'] as bool? ?? false;
    final title = data['title'] as String? ?? '(No title)';
    final message = data['message'] as String? ?? '';
    final ts = data['createdAt'] as Timestamp?;
    final timeStr = ts != null ? _timeStr(ts) : '';
    final notifType = _notifTypeOf(doc);
    final typeColor = notifType.color;
    final typeIcon = notifType.icon;
    final isDark = theme.brightness == Brightness.dark;

    // Subtle tinted background color for the card
    final cardBg = isRead
        ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
        : (isDark
              ? Color.alphaBlend(
                  typeColor.withOpacity(0.10),
                  const Color(0xFF1C1C1E),
                )
              : Color.alphaBlend(typeColor.withOpacity(0.04), Colors.white));

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            SizedBox(height: 3),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await _deleteDoc(doc);
        return false;
      },

      child: GestureDetector(
        onTap: () => _markSingleRead(doc),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isRead
                  ? (isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06))
                  : typeColor.withOpacity(isDark ? 0.35 : 0.2),
              width: 1,
            ),
            boxShadow: isRead
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: typeColor.withOpacity(isDark ? 0.25 : 0.13),
                      blurRadius: 22,
                      spreadRadius: -3,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.35 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Large icon bubble ───────────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    // Unread: vivid solid. Read: very faint tint.
                    color: isRead
                        ? typeColor.withOpacity(isDark ? 0.12 : 0.08)
                        : typeColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isRead
                        ? []
                        : [
                            BoxShadow(
                              color: typeColor.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Icon(
                    typeIcon,
                    size: 24,
                    color: isRead ? typeColor.withOpacity(0.55) : Colors.white,
                  ),
                ),

                const SizedBox(width: 14),

                // ── Text content ────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top row: type pill + time ────────────────────────────
                      Row(
                        children: [
                          // Category pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? (isDark
                                        ? Colors.white.withOpacity(0.07)
                                        : Colors.black.withOpacity(0.05))
                                  : typeColor.withOpacity(isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              notifType.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isRead
                                    ? (isDark
                                          ? Colors.white.withOpacity(0.35)
                                          : Colors.black.withOpacity(0.3))
                                    : typeColor.withOpacity(isDark ? 0.9 : 0.8),
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Time
                          if (timeStr.isNotEmpty)
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white.withOpacity(
                                        isRead ? 0.25 : 0.45,
                                      )
                                    : Colors.black.withOpacity(
                                        isRead ? 0.25 : 0.4,
                                      ),
                              ),
                            ),
                          // Unread dot
                          if (!isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: typeColor.withOpacity(0.5),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 7),

                      // ── Title ──────────────────────────────────────────────────
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: isDark
                              ? Colors.white.withOpacity(isRead ? 0.45 : 0.92)
                              : Colors.black.withOpacity(isRead ? 0.4 : 0.88),
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),

                      // ── Message ────────────────────────────────────────────────
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? Colors.white.withOpacity(isRead ? 0.28 : 0.58)
                                : Colors.black.withOpacity(isRead ? 0.3 : 0.55),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────────
  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Could not load notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────────
  Widget _buildEmptyState(ThemeData theme) {
    final isFiltered = _activeFilter != _kAllFilter;
    // Get the label for the active filter chip
    final filterLabel = isFiltered
        ? _NotifTypeX.fromString(_activeFilter).label
        : '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered
                    ? Icons.filter_list_off_rounded
                    : Icons.notifications_off_outlined,
                size: 42,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'No $filterLabel Notifications' : 'All Caught Up!',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'No $filterLabel notifications yet.\nTry a different filter.'
                  : 'Smart notifications will appear here\nas you use the app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => setState(() => _activeFilter = _kAllFilter),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Show All'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
