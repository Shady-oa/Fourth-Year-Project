// ============================================================
//  notifications_page.dart
//  Fully offline, local-storage-backed notifications page.
//  Features: grouping by date, filtering, mark all read,
//  badge counter, dynamic card heights, Poppins font,
//  pull-to-refresh, swipe-to-delete.
// ============================================================

import 'package:final_project/Primary_Screens/Notifications/notification_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─── Color Palette (matches app theme) ───────────────────────────────────────
const Color _brandGreen = Color(0xFF43A047);
const Color _accentColor = Color(0xFF42A5F5);
const Color _errorColor = Color(0xFFEF5350);

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  List<LocalNotification> _all = [];
  List<LocalNotification> _filtered = [];
  bool _isLoading = true;

  // Current filter — null means 'All'
  NotificationType? _activeFilter;

  // Tab controller for filter chips
  late TabController _tabController;

  // Filter options including "All"
  final _filterOptions = [null, ...NotificationType.values];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _filterOptions.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _load();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() => _isLoading = true);

    // Auto-delete old notifications (30 days)
    await NotificationService.autoDeleteOld(days: 30);

    final all = await NotificationService.fetchNotifications();

    if (!mounted) return;
    setState(() {
      _all = all;
      _applyFilter();
      _isLoading = false;
    });
  }

  void _applyFilter() {
    if (_activeFilter == null) {
      _filtered = List.from(_all);
    } else {
      _filtered = _all.where((n) => n.type == _activeFilter).toList();
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    setState(() {
      _activeFilter = _filterOptions[_tabController.index];
      _applyFilter();
    });
  }

  // ── Mark as read (when user views page — on dispose) ─────────────────────
  @override
  void deactivate() {
    NotificationService.markAllAsRead();
    super.deactivate();
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _markAllRead() async {
    await NotificationService.markAllAsRead();
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: _brandGreen,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteNotif(String id) async {
    await NotificationService.deleteNotification(id);
    await _load();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService.clearAll();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: _brandGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ── Grouping by date ─────────────────────────────────────────────────────
  /// Groups [_filtered] into { "Today" | "Yesterday" | "dd MMM yyyy" : [notifs] }
  Map<String, List<LocalNotification>> get _grouped {
    final map = <String, List<LocalNotification>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final notif in _filtered) {
      final d = notif.createdAt;
      final day = DateTime(d.year, d.month, d.day);
      String label;
      if (day == today) {
        label = 'Today';
      } else if (day == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('dd MMM yyyy').format(d);
      }
      map.putIfAbsent(label, () => []).add(notif);
    }
    return map;
  }

  int get _unreadCount => _all.where((n) => !n.isRead).length;

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(theme),
                Expanded(
                  child: _filtered.isEmpty
                      ? _buildEmptyState(theme)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: _accentColor,
                          child: ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 32,
                              top: 8,
                            ),
                            itemCount: _countItems(grouped),
                            itemBuilder: (ctx, i) =>
                                _buildItem(ctx, i, grouped),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      title: Row(
        children: [
          Text(
            'Notifications',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          if (_unreadCount > 0) ...[
            const SizedBox(width: 10),
            _Badge(count: _unreadCount),
          ],
        ],
      ),
      actions: [
        if (_all.isNotEmpty) ...[
          // Mark all as read
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: _markAllRead,
            color: _accentColor,
          ),
          // Clear all
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all',
            onPressed: _clearAll,
            color: _errorColor.withOpacity(0.8),
          ),
        ],
      ],
    );
  }

  // ── Filter Chips Row ─────────────────────────────────────────────────────
  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final option = _filterOptions[i];
          final isSelected = _activeFilter == option;
          final label = option == null ? 'All' : option.label;
          final color = option == null ? _accentColor : option.color;

          return GestureDetector(
            onTap: () {
              _tabController.index = i;
              setState(() {
                _activeFilter = option;
                _applyFilter();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option != null) ...[
                    Icon(
                      option.icon,
                      size: 13,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── ListView item builder ─────────────────────────────────────────────────
  /// Builds flat list: date headers + notification cards
  int _countItems(Map<String, List<LocalNotification>> grouped) {
    int count = 0;
    for (final group in grouped.entries) {
      count += 1 + group.value.length; // 1 header + n cards
    }
    return count;
  }

  Widget _buildItem(
    BuildContext ctx,
    int index,
    Map<String, List<LocalNotification>> grouped,
  ) {
    int cursor = 0;
    for (final entry in grouped.entries) {
      if (index == cursor) {
        // Date header
        return _buildDateHeader(entry.key);
      }
      cursor++;
      final notifications = entry.value;
      if (index < cursor + notifications.length) {
        final notif = notifications[index - cursor];
        return _buildNotificationCard(notif);
      }
      cursor += notifications.length;
    }
    return const SizedBox.shrink();
  }

  // ── Date Header ───────────────────────────────────────────────────────────
  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  // ── Notification Card ─────────────────────────────────────────────────────
  Widget _buildNotificationCard(LocalNotification notif) {
    final theme = Theme.of(context);
    final isRead = notif.isRead;
    final typeColor = notif.type.color;

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotif(notif.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _errorColor,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          if (!notif.isRead) {
            await NotificationService.markAsRead(notif.id);
            setState(() => notif.isRead = true);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isRead
                ? theme.colorScheme.surface
                : typeColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead
                  ? Colors.grey.withOpacity(0.15)
                  : typeColor.withOpacity(0.25),
              width: isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isRead ? 0.02 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Colored sidebar for unread
                  if (!isRead)
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomLeft: Radius.circular(14),
                        ),
                      ),
                    ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isRead ? 14 : 10,
                        12,
                        12,
                        12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Type icon circle
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              notif.type.icon,
                              color: typeColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Text content — dynamic height
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row + type badge
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13.5,
                                          fontWeight: isRead
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                          color: isRead
                                              ? theme.colorScheme.onSurface
                                                  .withOpacity(0.75)
                                              : theme.colorScheme.onSurface,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _TypeBadge(type: notif.type),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                // Message body
                                Text(
                                  notif.message,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                    color: isRead
                                        ? theme.colorScheme.onSurface
                                            .withOpacity(0.5)
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.85),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                // Timestamp
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 11,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatTime(notif.createdAt),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    if (!notif.isRead) ...[
                                      const Spacer(),
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: typeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState(ThemeData theme) {
    final hasFilter = _activeFilter != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                hasFilter
                    ? _activeFilter!.icon
                    : Icons.notifications_off_outlined,
                size: 42,
                color: _accentColor.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter
                  ? 'No ${_activeFilter!.label} Notifications'
                  : 'No Notifications Yet',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try switching to "All" to see everything.'
                  : 'Notifications about your budgets, savings, and insights will appear here.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.35),
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilter) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => setState(() {
                  _activeFilter = null;
                  _tabController.index = 0;
                  _applyFilter();
                }),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Show All',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Time formatting (24h) ────────────────────────────────────────────────
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(dt.year, dt.month, dt.day);

    final timeStr = DateFormat('HH:mm').format(dt);
    if (day == today) return 'Today at $timeStr';
    if (day == yesterday) return 'Yesterday at $timeStr';
    return '${DateFormat('dd MMM').format(dt)} at $timeStr';
  }
}

// ─── Badge Widget ─────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _errorColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Type Badge Widget ────────────────────────────────────────────────────────
class _TypeBadge extends StatelessWidget {
  final NotificationType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: type.color.withOpacity(0.2)),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: type.color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Notification Icon Button (for AppBar use) ────────────────────────────────
/// Drop-in replacement for your existing NotificationIcon component.
/// Shows a badge with unread count. Pass [userId] if you still want
/// Firebase fallback — otherwise it reads from local storage only.
class NotificationIconButton extends StatefulWidget {
  const NotificationIconButton({super.key});

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final count = await NotificationService.unreadCount();
    if (mounted) setState(() => _unread = count);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsPage(),
              ),
            );
            // Refresh badge after returning
            await _refresh();
          },
        ),
        if (_unread > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: _errorColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _unread > 9 ? '9+' : '$_unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}