import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'local_notification_service.dart';

class NotificationService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _notifications = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      await loadNotifications();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      await loadNotifications();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  void subscribeToNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            // Show local notification
            final newNotification = payload.newRecord;
            if (newNotification != null) {
              LocalNotificationService.showNotification(
                id: newNotification['id'].hashCode,
                title: newNotification['title'] ?? 'New Notification',
                body: newNotification['message'] ?? '',
                payload: newNotification['id'],
              );
            }
            
            loadNotifications();
          },
        )
        .subscribe();
  }

  void unsubscribeFromNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase.channel('notifications_$userId').unsubscribe();
  }

  @override
  void dispose() {
    unsubscribeFromNotifications();
    super.dispose();
  }
}
