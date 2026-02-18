import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../entities/vaccine_schedule.dart';

class VaccinationNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);
  }

  /// Schedule a notification for an upcoming vaccine
  static Future<void> scheduleVaccineReminder({
    required String batchId,
    required String vaccineName,
    required int ageInDays,
    required DateTime batchStartDate,
  }) async {
    final scheduledDate = batchStartDate.add(Duration(days: ageInDays));
    
    // Set reminder for the day before
    final reminderDate = scheduledDate.subtract(const Duration(days: 1));

    if (reminderDate.isBefore(DateTime.now())) {
      return; // Don't schedule past dates
    }

    await _notificationsPlugin.zonedSchedule(
      batchId.hashCode + vaccineName.hashCode,
      'Vaccination Reminder',
      '$vaccineName is due tomorrow for your batch!',
      tz.TZDateTime.from(reminderDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vaccination_channel',
          'Vaccination Reminders',
          channelDescription: 'Reminders for upcoming vaccinations',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule reminders for all vaccines in a schedule
  static Future<void> scheduleAllReminders({
    required String batchId,
    required List<VaccineSchedule> schedules,
    required DateTime batchStartDate,
  }) async {
    for (final schedule in schedules) {
      await scheduleVaccineReminder(
        batchId: batchId,
        vaccineName: schedule.vaccineName,
        ageInDays: schedule.ageInDays,
        batchStartDate: batchStartDate,
      );
    }
  }

  /// Cancel all notifications for a batch
  static Future<void> cancelAllReminders(String batchId) async {
    await _notificationsPlugin.cancelAll();
  }

  /// Show immediate notification (for testing)
  static Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      0,
      'Test Notification',
      'Vaccination reminder test',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'vaccination_channel',
          'Vaccination Reminders',
          channelDescription: 'Reminders for upcoming vaccinations',
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
