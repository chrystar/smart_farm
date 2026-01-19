import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../features/settings/domain/entities/user_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Set device's local timezone
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.toString()));
      debugPrint('🌍 Timezone set to: $timeZoneInfo');
    } catch (e) {
      debugPrint('⚠️ Error setting timezone, using UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (initialized == true) {
      // Request permissions explicitly
      await _requestPermissions();
      _initialized = true;
      debugPrint('✅ Notification service initialized successfully');
    } else {
      debugPrint('❌ Failed to initialize notification service');
    }
  }

  Future<bool> _requestPermissions() async {
    // Request Android permissions
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await androidPlugin?.requestNotificationsPermission();
    
    // Request iOS permissions
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted = androidGranted ?? iosGranted ?? false;
    debugPrint('🔔 Notification permissions granted: $granted');
    return granted;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  // Schedule feeding notification
  Future<void> scheduleFeedingNotification(FeedingSchedule schedule) async {
    if (!_initialized) {
      debugPrint('⚠️ Notification service not initialized');
      return;
    }

    try {
      final scheduledTime = _nextInstanceOfTime(schedule.time);
      debugPrint('📅 Scheduling feeding notification: ${schedule.name} at $scheduledTime');
      
      await _notifications.zonedSchedule(
        schedule.id.hashCode,
        'Feeding Time: ${schedule.name}',
        'It\'s time to feed your birds!',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'feeding_channel',
            'Feeding Notifications',
            channelDescription: 'Notifications for feeding times',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      debugPrint('✅ Feeding notification scheduled successfully');
    } catch (e) {
      debugPrint('❌ Error scheduling feeding notification: $e');
    }
  }

  // Cancel feeding notification
  Future<void> cancelFeedingNotification(String scheduleId) async {
    try {
      await _notifications.cancel(scheduleId.hashCode);
      debugPrint('🗑️ Cancelled feeding notification: $scheduleId');
    } catch (e) {
      debugPrint('❌ Error cancelling feeding notification: $e');
    }
  }

  // Schedule daily report reminder
  Future<void> scheduleDailyReportReminder(TimeOfDay time) async {
    if (!_initialized) {
      debugPrint('⚠️ Notification service not initialized');
      return;
    }

    try {
      final scheduledTime = _nextInstanceOfTime(time);
      debugPrint('📅 Scheduling daily report reminder at $scheduledTime');
      
      await _notifications.zonedSchedule(
        999999, // Fixed ID for daily report reminder
        'Daily Report Reminder',
        'Don\'t forget to record today\'s mortality data!',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_report_channel',
            'Daily Report Reminders',
            channelDescription: 'Reminders to record daily mortality reports',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      debugPrint('✅ Daily report reminder scheduled successfully');
    } catch (e) {
      debugPrint('❌ Error scheduling daily report reminder: $e');
    }
  }

  // Cancel daily report reminder
  Future<void> cancelDailyReportReminder() async {
    try {
      await _notifications.cancel(999999);
      debugPrint('🗑️ Cancelled daily report reminder');
    } catch (e) {
      debugPrint('❌ Error cancelling daily report reminder: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('🗑️ Cancelled all notifications');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Test notification - for debugging
  Future<void> showTestNotification() async {
    if (!_initialized) {
      debugPrint('⚠️ Notification service not initialized');
      return;
    }

    try {
      await _notifications.show(
        12345,
        'Test Notification',
        'If you see this, notifications are working! 🎉',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notification channel',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('✅ Test notification sent');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  // Schedule a test notification for 10 seconds from now
  Future<void> scheduleTestNotification() async {
    if (!_initialized) {
      debugPrint('⚠️ Notification service not initialized');
      return;
    }

    try {
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
      
      await _notifications.zonedSchedule(
        12346,
        'Scheduled Test Notification',
        'This notification was scheduled 10 seconds ago! 🎉',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Test notification channel',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      debugPrint('✅ Test notification scheduled for: $scheduledTime');
    } catch (e) {
      debugPrint('❌ Error scheduling test notification: $e');
    }
  }

  // Debug: list pending scheduled notifications
  Future<void> debugPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      debugPrint('🔎 Pending notifications count: ${pending.length}');
      for (final p in pending) {
        debugPrint(' - id=${p.id}, title=${p.title}, body=${p.body}, payload=${p.payload}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching pending notifications: $e');
    }
  }
}
