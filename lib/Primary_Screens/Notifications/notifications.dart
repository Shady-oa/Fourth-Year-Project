import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  final String userId;

  const NotificationsPage({super.key, required this.userId});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Logic moved to dispose to keep them bold while viewing
  }

  @override
  void dispose() {
    // Only mark as read when the user navigates away from this screen
    _markNotificationsAsRead();
    super.dispose();
  }

  Future<void> _markNotificationsAsRead() async {
    final unreadNotifications = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  String _formatNotificationDate(Timestamp timestamp) {
    final DateTime notificationDate = timestamp.toDate();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final DateTime notificationDay = DateTime(
      notificationDate.year,
      notificationDate.month,
      notificationDate.day,
    );

    if (notificationDay == today) return 'Today';
    if (notificationDay == yesterday) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(notificationDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text("All Transactions"),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          // Grouping logic for Date Headers
          Map<String, List<QueryDocumentSnapshot>> groupedNotifications = {};
          for (var doc in snapshot.data!.docs) {
            String label = _formatNotificationDate(doc['createdAt']);
            groupedNotifications.putIfAbsent(label, () => []).add(doc);
          }

          List<String> dateKeys = groupedNotifications.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: dateKeys.length,
            itemBuilder: (context, index) {
              String dateLabel = dateKeys[index];
              List<QueryDocumentSnapshot> notifications =
                  groupedNotifications[dateLabel]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      dateLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.7),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ...notifications
                      .map((doc) => _buildNotificationItem(doc, context))
                      .toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    QueryDocumentSnapshot doc,
    BuildContext context,
  ) {
    bool isRead = doc['isRead'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isRead
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          boxShadow: isRead
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: isRead
                ? Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)
                : Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Highlight Sidebar for Unread Messages
                if (!isRead)
                  Container(
                    width: 6,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                Expanded(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundImage: const AssetImage(
                        "assets/image/icon 2.png",
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    title: Text(
                      doc['title'],
                      style: TextStyle(
                        // FontWeight.black is the heaviest available weight
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                        fontSize: 15,
                        color: isRead
                            ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        doc['message'],
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                          color: isRead
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.9),
                        ),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.delete_sweep_outlined,
                            color: Theme.of(
                              context,
                            ).colorScheme.error.withOpacity(0.7),
                            size: 22,
                          ),
                          onPressed: () => doc.reference.delete(),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
