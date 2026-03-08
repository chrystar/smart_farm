import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationModel>> _notificationsFuture;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<NotificationModel>> _loadNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notification.id);

      setState(() {
        _notificationsFuture = _loadNotifications();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      setState(() {
        _notificationsFuture = _loadNotifications();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);

      setState(() {
        _notificationsFuture = _loadNotifications();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = _loadNotifications();
    });
    await _notificationsFuture;
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'report_response':
        return Icons.medical_services;
      case 'alert':
        return Icons.warning;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'report_response':
        return Colors.green;
      case 'alert':
        return Colors.orange;
      case 'system':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<NotificationModel>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Failed to load notifications: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final dateFormatter = DateFormat('MMM d, yyyy • HH:mm');

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final color = _getColorForType(notification.type);
                final icon = _getIconForType(notification.type);

                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteNotification(notification.id);
                  },
                  child: Card(
                    color: notification.isRead
                        ? null
                        : color.withOpacity(0.1),
                  child: InkWell(
                    onTap: () async {
                      // Mark as read
                      await _markAsRead(notification);
                      
                      // Navigate to detail screen if it's a report response
                      if (notification.type == 'report_response' && 
                          notification.referenceId != null && 
                          mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationDetailScreen(
                              responseId: notification.referenceId!,
                              notificationId: notification.id,
                            ),
                          ),
                        ).then((_) {
                          // Refresh notifications when returning
                          _refresh();
                        });
                      }
                    },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color),
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
                                          notification.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: notification.isRead
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (!notification.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.message,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    dateFormatter.format(notification.createdAt.toLocal()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
