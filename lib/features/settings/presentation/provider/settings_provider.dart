
import 'package:flutter/material.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/usecases/get_preferences_usecase.dart';
import '../../domain/usecases/save_preferences_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/notification_usecases.dart';

class SettingsProvider with ChangeNotifier {
  final GetPreferencesUseCase getPreferencesUseCase;
  final SavePreferencesUseCase savePreferencesUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final ScheduleFeedingNotificationUseCase scheduleFeedingNotificationUseCase;
  final CancelFeedingNotificationUseCase cancelFeedingNotificationUseCase;
  final ScheduleDailyReportReminderUseCase scheduleDailyReportReminderUseCase;
  final CancelDailyReportReminderUseCase cancelDailyReportReminderUseCase;

  SettingsProvider({
    required this.getPreferencesUseCase,
    required this.savePreferencesUseCase,
    required this.updateProfileUseCase,
    required this.scheduleFeedingNotificationUseCase,
    required this.cancelFeedingNotificationUseCase,
    required this.scheduleDailyReportReminderUseCase,
    required this.cancelDailyReportReminderUseCase,
  });

  UserPreferences? _preferences;
  bool _isLoading = false;
  String? _errorMessage;

  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPreferences(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await getPreferencesUseCase(userId);
    result.fold(
      (failure) => _errorMessage = failure.toString(),
      (preferences) => _preferences = preferences,
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updatePreference(UserPreferences preferences) async {
    final result = await savePreferencesUseCase(preferences);
    result.fold(
      (failure) => _errorMessage = failure.toString(),
      (_) {
        _preferences = preferences;
        notifyListeners();
      },
    );
  }

    Future<void> setVaccinationAlarmTime(TimeOfDay time, String userId) async {
    if (_preferences == null) return;

    // Update preferences
    final updatedPrefs = _preferences!.copyWith(vaccinationAlarmTime: time);
    await updatePreference(updatedPrefs);

    // Reschedule the vaccination alarm
    // (Assumes you have a VaccinationAlarmService with a method to reschedule)
    // import your alarm service and call:
    // await VaccinationAlarmService.scheduleDailyAlarmAt(time);
  }

  Future<void> updateProfile({
    required String userId,
    String? farmName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final result = await updateProfileUseCase(
      userId: userId,
      farmName: farmName,
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
    );

    result.fold(
      (failure) => _errorMessage = failure.toString(),
      (_) async {
        // Reload preferences
        await loadPreferences(userId);
      },
    );
  }

  Future<void> addFeedingSchedule(FeedingSchedule schedule, String userId) async {
    if (_preferences == null) return;

    final updatedSchedules = List<FeedingSchedule>.from(_preferences!.feedingSchedules)
      ..add(schedule);

    final updatedPrefs = _preferences!.copyWith(feedingSchedules: updatedSchedules);
    
    await updatePreference(updatedPrefs);
    await scheduleFeedingNotificationUseCase(schedule);
  }

  Future<void> removeFeedingSchedule(String scheduleId, String userId) async {
    if (_preferences == null) return;

    final updatedSchedules = _preferences!.feedingSchedules
        .where((s) => s.id != scheduleId)
        .toList();

    final updatedPrefs = _preferences!.copyWith(feedingSchedules: updatedSchedules);
    
    await updatePreference(updatedPrefs);
    await cancelFeedingNotificationUseCase(scheduleId);
  }

  Future<void> toggleFeedingSchedule(String scheduleId, bool enabled, String userId) async {
    if (_preferences == null) return;

    final updatedSchedules = _preferences!.feedingSchedules.map((s) {
      if (s.id == scheduleId) {
        return s.copyWith(enabled: enabled);
      }
      return s;
    }).toList();

    final updatedPrefs = _preferences!.copyWith(feedingSchedules: updatedSchedules);
    
    await updatePreference(updatedPrefs);

    final schedule = updatedSchedules.firstWhere((s) => s.id == scheduleId);
    if (enabled) {
      await scheduleFeedingNotificationUseCase(schedule);
    } else {
      await cancelFeedingNotificationUseCase(scheduleId);
    }
  }

  Future<void> setDailyReportReminder(TimeOfDay? time, String userId) async {
    if (_preferences == null) return;

    if (time != null) {
      await scheduleDailyReportReminderUseCase(time);
    } else {
      await cancelDailyReportReminderUseCase();
    }

    final updatedPrefs = _preferences!.copyWith(dailyReportReminderTime: time);
    await updatePreference(updatedPrefs);
  }

  Future<void> updateCurrency(String userId, String currency) async {
    if (_preferences == null) return;
    final updatedPrefs = _preferences!.copyWith(defaultCurrency: currency);
    await updatePreference(updatedPrefs);
  }

  Future<void> updateThemeMode(String userId, String themeMode) async {
    if (_preferences == null) return;
    final updatedPrefs = _preferences!.copyWith(themeMode: themeMode);
    await updatePreference(updatedPrefs);
  }

  Future<void> toggleNotification(String type, bool value, String userId) async {
    if (_preferences == null) return;

    UserPreferences updatedPrefs;
    switch (type) {
      case 'push':
        updatedPrefs = _preferences!.copyWith(pushNotifications: value);
        break;
      case 'email':
        updatedPrefs = _preferences!.copyWith(emailNotifications: value);
        break;
      case 'highMortality':
        updatedPrefs = _preferences!.copyWith(highMortalityAlerts: value);
        break;
      case 'missingRecord':
        updatedPrefs = _preferences!.copyWith(missingRecordAlerts: value);
        break;
      default:
        return;
    }

    await updatePreference(updatedPrefs);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
