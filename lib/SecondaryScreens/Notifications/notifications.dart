
import 'package:final_project/SecondaryScreens/Notifications/app_notification.dart';
import 'package:final_project/SecondaryScreens/Notifications/delete_confirm_sheet.dart';
import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_card.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_empty_state.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_filter_row.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_ui_helpers.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_unread_banner.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
    final selectedType = notificationFilters[_filterIdx].type;
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
      builder: (ctx) => DeleteConfirmSheet(
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
                  child: _buildBody(theme, isDark, unread),
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
  Widget _buildBody(ThemeData theme, bool isDark, int unread) {
    return Column(
      children: [
        // ── Filter tabs ──────────────────────────────────────────────────
        if (!_isSelectMode)
          NotificationFilterRow(
            selectedIndex: _filterIdx,
            onSelected: (i) {
              setState(() {
                _filterIdx = i;
                _applyFilter();
              });
              _fadeCtrl.forward(from: 0);
            },
          ),

        // ── Unread banner ────────────────────────────────────────────────
        if (!_isSelectMode && unread > 0)
          NotificationUnreadBanner(
            count: unread,
            onMarkAllRead: _markAllAsRead,
          ),

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
              ? NotificationEmptyState(filterIndex: _filterIdx)
              : _buildList(theme, isDark),
        ),
      ],
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
        ...notifs.map(
          (n) => NotificationCard(
            notif: n,
            isSelectMode: _isSelectMode,
            isSelected: _selectedIds.contains(n.id),
            onToggleSelect: () => _toggleSelect(n.id),
            onEnterSelectMode: () => _enterSelectMode(n.id),
            onExitSelectMode: _exitSelectMode,
            onDeleteSingle: _deleteSingle,
            onMarkRead: _loadNotifications,
          ),
        ),
      ],
    );
  }
}
