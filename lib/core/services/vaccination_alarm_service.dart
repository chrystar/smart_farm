
import 'dart:typed_data';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/vaccination/data/datasources/vaccination_remote_datasource.dart';

class VaccinationAlarmService {
  static const int alarmId = 0;
  static const int dailyAlarmId = 1;

  static FlutterLocalNotificationsPlugin? _notificationsPlugin;

  static Future<void> initialize() async {
    // Initialize Android Alarm Manager
    await AndroidAlarmManager.initialize();

    // Initialize notifications
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notificationsPlugin!.initialize(initSettings);

    final androidPlugin = _notificationsPlugin!
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notificationsPlugin!
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Schedule daily alarm at 6 AM
  static Future<void> scheduleDailyAlarm() async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, 6, 0, 0);
    
    // If 6 AM has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      dailyAlarmId,
      checkVaccinationsCallback,
      startAt: scheduledTime,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  /// Cancel the daily alarm
  static Future<void> cancelDailyAlarm() async {
    await AndroidAlarmManager.cancel(dailyAlarmId);
  }
    /// Schedule daily alarm at a custom time
  static Future<void> scheduleDailyAlarmAt(TimeOfDay time) async {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute, 0);
    // If the selected time has already passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      dailyAlarmId,
      checkVaccinationsCallback,
      startAt: scheduledTime,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  /// Callback that runs at 6 AM daily - must be a top-level or static function
  @pragma('vm:entry-point')
  static Future<void> checkVaccinationsCallback() async {
    try {
      // Read batch info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final batchId = prefs.getString('batch_id');
      final batchName = prefs.getString('batch_name');
      final batchStartDateStr = prefs.getString('batch_start_date');
      if (batchId == null || batchName == null || batchStartDateStr == null) return;
      final batchStartDate = DateTime.parse(batchStartDateStr);

      // Get default schedules
      final dataSource = VaccinationRemoteDataSourceImpl(supabaseClient: Supabase.instance.client);
      final defaultSchedules = await dataSource.getDefaultSchedules();

      final currentDay = DateTime.now().difference(batchStartDate).inDays + 1;
      int totalVaccinations = 0;
      final batchesWithVaccinations = <String>[];

      for (final schedule in defaultSchedules) {
        final ageInDays = schedule.ageInDays;

        // Calculate day range using duration field
        final durationDays = schedule.durationDays;
        int startDay = ageInDays;
        int endDay = ageInDays + durationDays - 1;

        // Check if vaccination is due today
        if (currentDay >= startDay && currentDay <= endDay) {
          totalVaccinations++;
          if (!batchesWithVaccinations.contains(batchName)) {
            batchesWithVaccinations.add(batchName);
          }
        }
      }

      // Show alarm notification if there are vaccinations due
      if (totalVaccinations > 0) {
        await _showVaccinationAlarm(totalVaccinations, batchesWithVaccinations);
      }
    } catch (e) {
      print('Error in vaccination alarm: $e');
    }
  }

  /// Show high-priority notification with alarm sound
  static Future<void> _showVaccinationAlarm(
    int count,
    List<String> batchNames,
  ) async {
    if (_notificationsPlugin == null) {
      _notificationsPlugin = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _notificationsPlugin!.initialize(initSettings);
    }

    final androidDetails = AndroidNotificationDetails(
      'vaccination_alarm_channel',
      'Vaccination Alarms',
      channelDescription: 'Daily vaccination reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      sound: const RawResourceAndroidNotificationSound('alarm'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'alarm.aiff',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final batchText = batchNames.length == 1
        ? batchNames.first
        : '${batchNames.length} batches';

    await _notificationsPlugin!.show(
      alarmId,
      '🔔 Vaccination Reminder',
      '$count vaccination${count > 1 ? 's' : ''} due today for $batchText',
      details,
    );
  }

  /// Manually trigger vaccination check (for testing)
  static Future<void> checkNow() async {
    await checkVaccinationsCallback();
  }
}
