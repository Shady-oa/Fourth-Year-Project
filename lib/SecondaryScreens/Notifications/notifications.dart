import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─── Notification Type UI extensions ─────────────────────────────────────────
extension _NotifTypeUI on NotificationType {
  // Icon per notification type — color is handled uniformly by the theme.
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

  // ── Select-to-delete state ────────────────────────────────────────────────
  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

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

  // ── Select-to-delete helpers ──────────────────────────────────────────────
  void _enterSelectMode(String firstId) {
    setState(() {
      _isSelectMode = true;
      _selectedIds.clear();
      _selectedIds.add(firstId);
    });
  }

  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  /// Shows a bottom sheet asking the user to confirm deletion of selected items.
  Future<void> _confirmDeleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DeleteConfirmSheet(
        count: count,
        onConfirm: () async {
          final ids = List<String>.from(_selectedIds);
          for (final id in ids) {
            await LocalNotificationStore.deleteNotification(id);
          }
          _exitSelectMode();
          await _loadNotifications();
        },
      ),
    );
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

    // Shade background — slightly tinted vs plain surface
    final shadeBg = isDark
        ? Color.alphaBlend(
            theme.colorScheme.primary.withOpacity(0.04),
            theme.colorScheme.surface,
          )
        : Color.alphaBlend(
            theme.colorScheme.primary.withOpacity(0.03),
            theme.colorScheme.surface,
          );

    return PopScope(
      onPopInvoked: (_) {
        if (_isSelectMode) {
          _exitSelectMode();
        }
      },
      child: Scaffold(
        backgroundColor: shadeBg,
        appBar: _buildAppBar(theme, isDark, shadeBg, unread),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadNotifications,
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: _buildBody(theme, isDark, unread, shadeBg),
                ),
              ),
        // ── Delete FAB (select mode) ────────────────────────────────────────
        floatingActionButton: _isSelectMode
            ? FloatingActionButton.extended(
                backgroundColor: _selectedIds.isEmpty
                    ? theme.colorScheme.surface
                    : const Color(0xFFFF3B30),
                foregroundColor: _selectedIds.isEmpty
                    ? theme.colorScheme.onSurface
                    : Colors.white,
                icon: Icon(
                  _selectedIds.isEmpty ? Icons.close : Icons.delete_rounded,
                ),
                label: Text(
                  _selectedIds.isEmpty
                      ? 'Cancel'
                      : 'Delete ${_selectedIds.length}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                onPressed: _selectedIds.isEmpty
                    ? _exitSelectMode
                    : _confirmDeleteSelected,
              )
            : null,
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    bool isDark,
    Color shadeBg,
    int unread,
  ) {
    return AppBar(
      backgroundColor: shadeBg,
      elevation: 0,
      centerTitle: true,
      leading: _isSelectMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _exitSelectMode,
              tooltip: 'Cancel selection',
            )
          : null,
      title: _isSelectMode
          ? Text(
              _selectedIds.isEmpty
                  ? 'Select notifications'
                  : '${_selectedIds.length} selected',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            )
          : Text(
              'Notifications',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
      actions: _isSelectMode
          ? [
              if (_shown.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == _shown.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds.addAll(_shown.map((n) => n.id));
                      }
                    });
                  },
                  child: Text(
                    _selectedIds.length == _shown.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
            ]
          : [
              if (unread > 0)
                IconButton(
                  tooltip: 'Mark all as read',
                  icon: const Icon(Icons.done_all_rounded),
                  onPressed: _markAllAsRead,
                ),
            ],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(ThemeData theme, bool isDark, int unread, Color shadeBg) {
    return Column(
      children: [
        // ── Filter tabs ──────────────────────────────────────────────────
        if (!_isSelectMode) _buildFilterRow(theme),

        // ── Unread banner ────────────────────────────────────────────────
        if (!_isSelectMode && unread > 0) _buildUnreadBanner(theme, unread),

        // ── Select-mode instruction banner ───────────────────────────────
        if (_isSelectMode)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap cards to select. Long-press to exit selection mode.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
    final accent = theme.colorScheme.primary;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == _filterIdx;
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
                color: selected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? accent : accent.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Text(
                _filters[i].label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : accent.withOpacity(0.75),
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
      padding: EdgeInsets.only(bottom: _isSelectMode ? 96 : 32),
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
        ...notifs.map((n) => _buildCard(theme, isDark, n)),
      ],
    );
  }

  // ── Notification card ─────────────────────────────────────────────────────
  Widget _buildCard(ThemeData theme, bool isDark, AppNotification notif) {
    final accent = theme.colorScheme.primary;
    final typeIcon = notif.type.icon;
    final isRead = notif.isRead;
    final isSelected = _selectedIds.contains(notif.id);

    final cardBg = isSelected
        ? (isDark ? accent.withOpacity(0.18) : accent.withOpacity(0.09))
        : isRead
        ? (isDark ? const Color(0xFF1C1C1E) : Colors.white)
        : (isDark
              ? Color.alphaBlend(
                  accent.withOpacity(0.07),
                  const Color(0xFF1C1C1E),
                )
              : Color.alphaBlend(accent.withOpacity(0.03), Colors.white));

    final timeStr = DateFormat('HH:mm').format(notif.createdAt);

    // In select mode — no Dismissible; just tap-to-toggle-select
    if (_isSelectMode) {
      return GestureDetector(
        onTap: () => _toggleSelect(notif.id),
        onLongPress: _exitSelectMode,
        child: _cardContent(
          theme,
          isDark,
          notif,
          accent,
          typeIcon,
          isRead,
          isSelected,
          cardBg,
          timeStr,
        ),
      );
    }

    // Normal mode — swipe-to-delete + long-press to enter select
    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
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
        return false;
      },
      child: GestureDetector(
        onTap: () async {
          if (!isRead) {
            await LocalNotificationStore.markAsRead(notif.id);
            await _loadNotifications();
          }
        },
        onLongPress: () => _enterSelectMode(notif.id),
        child: _cardContent(
          theme,
          isDark,
          notif,
          accent,
          typeIcon,
          isRead,
          isSelected,
          cardBg,
          timeStr,
        ),
      ),
    );
  }

  Widget _cardContent(
    ThemeData theme,
    bool isDark,
    AppNotification notif,
    Color accent,
    IconData typeIcon,
    bool isRead,
    bool isSelected,
    Color cardBg,
    String timeStr,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      margin: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected
              ? accent.withOpacity(0.55)
              : isDark
              ? Colors.white.withOpacity(isRead ? 0.06 : 0.10)
              : Colors.black.withOpacity(isRead ? 0.06 : 0.08),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Checkbox (select mode) or icon bubble ─────────────────────
            if (_isSelectMode)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent
                      : accent.withOpacity(isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? Icons.check_rounded : typeIcon,
                  size: 24,
                  color: isSelected
                      ? Colors.white
                      : accent.withOpacity(isRead ? 0.5 : 0.9),
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isRead
                      ? accent.withOpacity(isDark ? 0.12 : 0.08)
                      : accent.withOpacity(isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  typeIcon,
                  size: 24,
                  color: accent.withOpacity(isRead ? 0.5 : 0.9),
                ),
              ),

            const SizedBox(width: 14),

            // ── Text content ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type pill + time + unread dot
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.07)
                              : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          notif.type.label.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark
                                ? Colors.white.withOpacity(0.40)
                                : Colors.black.withOpacity(0.35),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withOpacity(isRead ? 0.25 : 0.45)
                              : Colors.black.withOpacity(isRead ? 0.25 : 0.40),
                        ),
                      ),
                      if (!isRead && !_isSelectMode) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.4),
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
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      color: isDark
                          ? Colors.white.withOpacity(isRead ? 0.45 : 0.92)
                          : Colors.black.withOpacity(isRead ? 0.4 : 0.88),
                      height: 1.35,
                      letterSpacing: -0.2,
                    ),
                  ),

                  // Message body
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

// ─── Delete Confirm Bottom Sheet ──────────────────────────────────────────────
class _DeleteConfirmSheet extends StatefulWidget {
  final int count;
  final Future<void> Function() onConfirm;

  const _DeleteConfirmSheet({required this.count, required this.onConfirm});

  @override
  State<_DeleteConfirmSheet> createState() => _DeleteConfirmSheetState();
}

class _DeleteConfirmSheetState extends State<_DeleteConfirmSheet> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delete_rounded,
              color: Color(0xFFFF3B30),
              size: 30,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Delete ${widget.count} Notification${widget.count == 1 ? '' : 's'}?',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'The selected notification${widget.count == 1 ? '' : 's'} will be permanently removed.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.45),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _deleting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _deleting
                      ? null
                      : () async {
                          setState(() => _deleting = true);
                          await widget.onConfirm();
                          if (mounted) Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _deleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
