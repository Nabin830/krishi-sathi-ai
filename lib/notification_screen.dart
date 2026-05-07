import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_language.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }

  DateTime _readCreatedAt(Map<String, dynamic> data) {
    final value = data['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sortedDocs = [...docs];

    sortedDocs.sort((a, b) {
      final aDate = _readCreatedAt(a.data());
      final bDate = _readCreatedAt(b.data());

      return bDate.compareTo(aDate);
    });

    return sortedDocs;
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return AppLanguage.text('Date not available', 'मिति उपलब्ध छैन');
    }

    final date = value.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> _markAllAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final unreadDocs = docs.where((doc) {
      final data = doc.data();
      return data['isRead'] != true;
    }).toList();

    if (unreadDocs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in unreadDocs) {
      batch.update(doc.reference, {
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> _deleteNotification(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  Future<void> _deleteAllNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  IconData _notificationIcon(String type) {
    if (type == 'crop_report_reviewed') return Icons.verified;
    if (type == 'market_price') return Icons.store;
    if (type == 'weather_alert') return Icons.cloud;
    if (type == 'listing_update') return Icons.shopping_bag;

    return Icons.notifications;
  }

  Color _notificationColor(String type, bool isRead) {
    if (isRead) return Colors.blueGrey;

    if (type == 'crop_report_reviewed') return Colors.green;
    if (type == 'market_price') return Colors.orange;
    if (type == 'weather_alert') return Colors.blue;
    if (type == 'listing_update') return Colors.teal;

    return Colors.green;
  }

  int _unreadCount(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.where((doc) {
      final data = doc.data();
      return data['isRead'] != true;
    }).length;
  }

  Future<void> _confirmDeleteAll(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLanguage.text(
              'Delete all notifications?',
              'सबै सूचनाहरू हटाउने?',
            ),
          ),
          content: Text(
            AppLanguage.text(
              'All your notifications will be deleted.',
              'तपाईंका सबै सूचनाहरू हटाइनेछन्।',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLanguage.text('Cancel', 'रद्द गर्नुहोस्')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLanguage.text('Delete All', 'सबै हटाउनुहोस्')),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await _deleteAllNotifications(docs);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLanguage.text('All notifications deleted', 'सबै सूचनाहरू हटाइयो'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.language,
      builder: (context, language, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F3),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            title: Text(
              AppLanguage.text('Notifications', 'सूचनाहरू'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _notificationStream(),
              builder: (context, snapshot) {
                if (FirebaseAuth.instance.currentUser == null) {
                  return _emptyState(
                    icon: Icons.lock,
                    title: AppLanguage.text(
                      'Please login first',
                      'कृपया पहिले लगइन गर्नुहोस्',
                    ),
                    subtitle: AppLanguage.text(
                      'Notifications are available after login.',
                      'सूचनाहरू लगइन गरेपछि उपलब्ध हुन्छन्।',
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _errorState(snapshot.error.toString());
                }

                final docs = _sortDocs(snapshot.data?.docs ?? []);
                final unread = _unreadCount(docs);

                if (docs.isEmpty) {
                  return _emptyState(
                    icon: Icons.notifications_none,
                    title: AppLanguage.text(
                      'No notifications yet',
                      'अहिलेसम्म कुनै सूचना छैन',
                    ),
                    subtitle: AppLanguage.text(
                      'Important updates will appear here.',
                      'महत्त्वपूर्ण अपडेटहरू यहाँ देखिनेछन्।',
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _headerCard(
                      count: docs.length,
                      unreadCount: unread,
                      onMarkAllRead: unread == 0
                          ? null
                          : () => _markAllAsRead(docs),
                      onDeleteAll: () => _confirmDeleteAll(context, docs),
                    ),
                    const SizedBox(height: 16),
                    ...docs.map((doc) {
                      return _notificationCard(
                        context: context,
                        docId: doc.id,
                        data: doc.data(),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _headerCard({
    required int count,
    required int unreadCount,
    required VoidCallback? onMarkAllRead,
    required VoidCallback onDeleteAll,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Icon(Icons.notifications, color: Colors.green, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  unreadCount == 0
                      ? AppLanguage.text(
                          '$count notifications',
                          '$count सूचनाहरू',
                        )
                      : AppLanguage.text(
                          '$unreadCount new of $count notifications',
                          '$count मध्ये $unreadCount नयाँ सूचना',
                        ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMarkAllRead,
                  icon: const Icon(Icons.done_all),
                  label: Text(
                    AppLanguage.text('Mark all read', 'सबै पढिएको बनाउनुहोस्'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    disabledForegroundColor: Colors.white54,
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDeleteAll,
                  icon: const Icon(Icons.delete_sweep),
                  label: Text(AppLanguage.text('Delete all', 'सबै हटाउनुहोस्')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  Widget _notificationCard({
    required BuildContext context,
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final type = (data['type'] ?? '').toString();

    final title = AppLanguage.text(
      (data['title'] ?? '').toString(),
      (data['titleNe'] ?? '').toString(),
    );

    final body = AppLanguage.text(
      (data['body'] ?? '').toString(),
      (data['bodyNe'] ?? '').toString(),
    );

    final isRead = data['isRead'] == true;
    final createdAt = _formatDate(data['createdAt']);
    final color = _notificationColor(type, isRead);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (!isRead) {
          _markAsRead(docId);
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.green.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(_notificationIcon(type), color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title.trim().isEmpty
                        ? AppLanguage.text('Notification', 'सूचना')
                        : title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'read') {
                      await _markAsRead(docId);
                    }

                    if (value == 'delete') {
                      await _deleteNotification(docId);

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLanguage.text(
                              'Notification deleted',
                              'सूचना हटाइयो',
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem(
                        value: 'read',
                        child: Text(
                          AppLanguage.text('Mark as read', 'पढिएको बनाउनुहोस्'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(AppLanguage.text('Delete', 'हटाउनुहोस्')),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body.trim().isEmpty
                  ? AppLanguage.text(
                      'You have a new update.',
                      'तपाईंलाई नयाँ अपडेट आएको छ।',
                    )
                  : body,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    createdAt,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
                if (!isRead)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLanguage.text('New', 'नयाँ'),
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 58, color: Colors.green),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.red.withOpacity(0.20)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({
    Color color = Colors.white,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: borderColor == null ? null : Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.055),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
