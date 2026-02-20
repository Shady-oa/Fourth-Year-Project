import 'package:final_project/Primary_Screens/Notifications/local_notification_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─── Notification Type UI extensions ─────────────────────────────────────────
extension _NotifTypeUI on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.budget:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.savings:
        return Icons.savings_rounded;
      case NotificationType.streak:
        return Icons.local_fire_department_rounded;
      case NotificationType.analysis:
        return Icons.bar_chart_rounded;
      case NotificationType.report:
        return Icons.receipt_long_rounded;
      case NotificationType.insight:
        return Icons.lightbulb_rounded;
      case NotificationType.system:
        return Icons.info_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.budget:
        return const Color(0xFF6C63FF);
      case NotificationType.savings:
        return const Color(0xFF00B894);
      case NotificationType.streak:
        return const Color(0xFFE17055);
      case NotificationType.analysis:
        return const Color(0xFF0984E3);
      case NotificationType.report:
        return const Color(0xFF6C5CE7);
      case NotificationType.insight:
        return const Color(0xFFFDAA40);
      case NotificationType.system:
        return const Color(0xFF636E72);
    }
  }
}

// ─── Filter tab model ─────────────────────────────────────────────────────────
class _FilterTab {
  final String label;
  final NotificationType? type; // null means "All"
  const _FilterTab(this.label, this.type);
}

const _filters = [
  _FilterTab('All', null),
  _FilterTab('Budget', NotificationType.budget),
  _FilterTab('Savings', NotificationType.savings),
  _FilterTab('Streak', NotificationType.streak),
  _FilterTab('Reports', NotificationType.report),
  _FilterTab('AI', NotificationType.insight),
];

// ─── Notifications Page ───────────────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  /// [userId] kept for API backwards-compat with nav routes that still pass it.
  /// Not used internally — all data comes from [LocalNotificationStore].
  final String? userId;
  const NotificationsPage({super.key, this.userId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  // Local state
  List<AppNotification> _all = [];
  List<AppNotification> _shown = [];
  int _filterIdx = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _loadNotifications();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────
  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final data = await LocalNotificationStore.fetchNotifications();
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
      _applyFilter();
    });
    _fadeCtrl.forward(from: 0);
  }

  void _applyFilter() {
    final selectedType = _filters[_filterIdx].type;
    _shown = selectedType == null
        ? List.of(_all)
        : _all.where((n) => n.type == selectedType).toList();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _markAllAsRead() async {
    await LocalNotificationStore.markAllAsRead();
    await _loadNotifications();
  }

  Future<void> _deleteSingle(String id) async {
    await LocalNotificationStore.deleteNotification(id);
    await _loadNotifications();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear All Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete all notifications.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete All', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await LocalNotificationStore.clearAll();
    await _loadNotifications();
  }

  // ── Date grouping helper ──────────────────────────────────────────────────
  String _dateGroupLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return DateFormat('dd MMM yyyy').format(d);
  }

  /// Group [_shown] by date-label, preserving insertion order.
  Map<String, List<AppNotification>> _grouped() {
    final map = <String, List<AppNotification>>{};
    for (final n in _shown) {
      map.putIfAbsent(_dateGroupLabel(n.createdAt), () => []).add(n);
    }
    return map;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unread = _all.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme, unread),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: FadeTransition(
                opacity: _fadeCtrl,
                child: _buildBody(theme, isDark, unread),
              ),
            ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(ThemeData theme, int unread) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'Notifications',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      actions: [
        if (unread > 0)
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all_rounded),
            onPressed: _markAllAsRead,
          ),
        IconButton(
          tooltip: 'Clear all',
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: _clearAll,
        ),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(ThemeData theme, bool isDark, int unread) {
    return Column(
      children: [
        // ── Filter tabs ──────────────────────────────────────────────────
        _buildFilterRow(theme),

        // ── Unread banner ────────────────────────────────────────────────
        if (unread > 0) _buildUnreadBanner(theme, unread),

        // ── Notification list ────────────────────────────────────────────
        Expanded(
          child: _shown.isEmpty
              ? _buildEmptyState(theme)
              : _buildList(theme, isDark),
        ),
      ],
    );
  }

  // ── Filter tab row ────────────────────────────────────────────────────────
  Widget _buildFilterRow(ThemeData theme) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == _filterIdx;
          final tab = _filters[i];
          final tabColor = tab.type?.color ?? theme.colorScheme.primary;
          return GestureDetector(
            onTap: () {
              setState(() {
                _filterIdx = i;
                _applyFilter();
              });
              _fadeCtrl.forward(from: 0);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? tabColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? tabColor : tabColor.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Text(
                tab.label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : tabColor.withOpacity(0.85),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Unread banner ─────────────────────────────────────────────────────────
  Widget _buildUnreadBanner(ThemeData theme, int count) {
    return GestureDetector(
      onTap: _markAllAsRead,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.22),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
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
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Text(
              'Mark all read',
              style: GoogleFonts.poppins(
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

  // ── Grouped list ──────────────────────────────────────────────────────────
  Widget _buildList(ThemeData theme, bool isDark) {
    final groups = _grouped();
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final label = groups.keys.elementAt(i);
        return _buildDateGroup(theme, isDark, label, groups[label]!);
      },
    );
  }

  // ── Date group ────────────────────────────────────────────────────────────
  Widget _buildDateGroup(
    ThemeData theme,
    bool isDark,
    String label,
    List<AppNotification> notifs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group label + divider
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Row(
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withOpacity(0.35)
                      : Colors.black.withOpacity(0.3),
                  letterSpacing: 0.6,
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
        // Cards
        ...notifs.map((n) => _buildCard(theme, isDark, n)),
      ],
    );
  }

  // ── Notification card (dynamic height) ───────────────────────────────────
  Widget _buildCard(ThemeData theme, bool isDark, AppNotification notif) {
    final typeColor = notif.type.color;
    final typeIcon = notif.type.icon;
    final isRead = notif.isRead;

    final cardBg = isRead
        ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
        : (isDark
              ? Color.alphaBlend(
                  typeColor.withOpacity(0.10),
                  const Color(0xFF1C1C1E),
                )
              : Color.alphaBlend(typeColor.withOpacity(0.04), Colors.white));

    final timeStr = DateFormat('HH:mm').format(notif.createdAt);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      // Red delete background
      background: Container(
        margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
            const SizedBox(height: 3),
            Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        await _deleteSingle(notif.id);
        return false; // We handle removal ourselves
      },

      child: GestureDetector(
        onTap: () async {
          if (!isRead) {
            await LocalNotificationStore.markAsRead(notif.id);
            await _loadNotifications();
          }
        },
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
          // Padding wraps everything — card height is fully dynamic
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Type icon bubble ─────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isRead
                        ? typeColor.withOpacity(isDark ? 0.12 : 0.08)
                        : typeColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isRead
                        ? []
                        : [
                            BoxShadow(
                              color: typeColor.withOpacity(0.40),
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

                // ── Text content ─────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type pill + time + unread dot
                      Row(
                        children: [
                          // Type pill
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
                              notif.type.label.toUpperCase(),
                              style: GoogleFonts.poppins(
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
                          // Timestamp
                          Text(
                            timeStr,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withOpacity(
                                      isRead ? 0.25 : 0.45,
                                    )
                                  : Colors.black.withOpacity(
                                      isRead ? 0.25 : 0.40,
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

                      // Title
                      Text(
                        notif.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: isDark
                              ? Colors.white.withOpacity(isRead ? 0.45 : 0.92)
                              : Colors.black.withOpacity(isRead ? 0.4 : 0.88),
                          height: 1.35,
                          letterSpacing: -0.2,
                        ),
                      ),

                      // Message body — fully dynamic, no truncation
                      if (notif.message.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          notif.message,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            height: 1.55,
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

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 42,
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'All Caught Up!',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filterIdx == 0
                  ? 'Smart notifications will appear here\nas you use the app.'
                  : 'No ${_filters[_filterIdx].label} notifications yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withOpacity(0.25)
                    : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
