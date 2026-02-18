import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class UserPreferences extends Equatable {
  final String userId;
  final String defaultCurrency;
  final String language;
  final String themeMode; // 'light', 'dark', 'system'
  final String dateFormat;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool highMortalityAlerts;
  final bool missingRecordAlerts;
  final int mortalityThreshold;
  final TimeOfDay? dailyReportReminderTime;
  final TimeOfDay? vaccinationAlarmTime;
  final List<FeedingSchedule> feedingSchedules;
  final String? defaultBirdType;
  final String? profileImageUrl;
  final String? farmName;
  final String? phoneNumber;

  const UserPreferences({
    required this.userId,
    this.defaultCurrency = 'USD',
    this.language = 'en',
    this.themeMode = 'system',
    this.dateFormat = 'MM/dd/yyyy',
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.highMortalityAlerts = true,
    this.missingRecordAlerts = true,
    this.mortalityThreshold = 5,
    this.dailyReportReminderTime,
    this.vaccinationAlarmTime,
    this.feedingSchedules = const [],
    this.defaultBirdType,
    this.profileImageUrl,
    this.farmName,
    this.phoneNumber,
  });

  UserPreferences copyWith({
    String? userId,
    String? defaultCurrency,
    String? language,
    String? themeMode,
    String? dateFormat,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? highMortalityAlerts,
    bool? missingRecordAlerts,
    int? mortalityThreshold,
    TimeOfDay? dailyReportReminderTime,
    TimeOfDay? vaccinationAlarmTime,
    List<FeedingSchedule>? feedingSchedules,
    String? defaultBirdType,
    String? profileImageUrl,
    String? farmName,
    String? phoneNumber,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      dateFormat: dateFormat ?? this.dateFormat,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      highMortalityAlerts: highMortalityAlerts ?? this.highMortalityAlerts,
      missingRecordAlerts: missingRecordAlerts ?? this.missingRecordAlerts,
      mortalityThreshold: mortalityThreshold ?? this.mortalityThreshold,
      dailyReportReminderTime: dailyReportReminderTime ?? this.dailyReportReminderTime,
      vaccinationAlarmTime: vaccinationAlarmTime ?? this.vaccinationAlarmTime,
      feedingSchedules: feedingSchedules ?? this.feedingSchedules,
      defaultBirdType: defaultBirdType ?? this.defaultBirdType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      farmName: farmName ?? this.farmName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        defaultCurrency,
        language,
        themeMode,
        dateFormat,
        pushNotifications,
        emailNotifications,
        highMortalityAlerts,
        missingRecordAlerts,
        mortalityThreshold,
        dailyReportReminderTime,
        vaccinationAlarmTime,
        feedingSchedules,
        defaultBirdType,
        profileImageUrl,
        farmName,
        phoneNumber,
      ];
}

class FeedingSchedule extends Equatable {
  final String id;
  final String name;
  final TimeOfDay time;
  final bool enabled;

  const FeedingSchedule({
    required this.id,
    required this.name,
    required this.time,
    this.enabled = true,
  });

  FeedingSchedule copyWith({
    String? id,
    String? name,
    TimeOfDay? time,
    bool? enabled,
  }) {
    return FeedingSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  List<Object?> get props => [id, name, time, enabled];
}
