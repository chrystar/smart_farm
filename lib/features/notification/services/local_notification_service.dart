import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    // Request permissions for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to notifications screen
    // This will be handled by the app's navigation logic
    debugPrint('Notification tapped: ${response.payload}');
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'vet_responses',
      'Vet Responses',
      channelDescription: 'Notifications for vet responses to droppings reports',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2E7D32), // Green color
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get badge count (iOS only)
  static Future<void> setBadgeCount(int count) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(badge: true);
    }
  }
}
