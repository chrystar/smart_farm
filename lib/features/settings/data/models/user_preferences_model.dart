import 'package:flutter/material.dart';
import '../../domain/entities/user_preferences.dart';
import 'dart:convert';

class UserPreferencesModel extends UserPreferences {
  const UserPreferencesModel({
    required super.userId,
    super.defaultCurrency,
    super.language,
    super.themeMode,
    super.dateFormat,
    super.pushNotifications,
    super.emailNotifications,
    super.highMortalityAlerts,
    super.missingRecordAlerts,
    super.mortalityThreshold,
    super.dailyReportReminderTime,
    super.feedingSchedules,
    super.defaultBirdType,
    super.profileImageUrl,
    super.farmName,
    super.phoneNumber,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      userId: json['userId'] as String,
      defaultCurrency: json['defaultCurrency'] as String? ?? 'USD',
      language: json['language'] as String? ?? 'en',
      themeMode: json['themeMode'] as String? ?? 'system',
      dateFormat: json['dateFormat'] as String? ?? 'MM/dd/yyyy',
      pushNotifications: json['pushNotifications'] as bool? ?? true,
      emailNotifications: json['emailNotifications'] as bool? ?? true,
      highMortalityAlerts: json['highMortalityAlerts'] as bool? ?? true,
      missingRecordAlerts: json['missingRecordAlerts'] as bool? ?? true,
      mortalityThreshold: json['mortalityThreshold'] as int? ?? 5,
      dailyReportReminderTime: json['dailyReportReminderTime'] != null
          ? _timeFromJson(json['dailyReportReminderTime'] as String)
          : null,
      feedingSchedules: json['feedingSchedules'] != null
          ? (jsonDecode(json['feedingSchedules']) as List)
              .map((e) => FeedingScheduleModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      defaultBirdType: json['defaultBirdType'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      farmName: json['farmName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'defaultCurrency': defaultCurrency,
      'language': language,
      'themeMode': themeMode,
      'dateFormat': dateFormat,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'highMortalityAlerts': highMortalityAlerts,
      'missingRecordAlerts': missingRecordAlerts,
      'mortalityThreshold': mortalityThreshold,
      'dailyReportReminderTime': dailyReportReminderTime != null
          ? _timeToJson(dailyReportReminderTime!)
          : null,
      'feedingSchedules': jsonEncode(
        feedingSchedules
            .map((e) => FeedingScheduleModel.fromEntity(e).toJson())
            .toList(),
      ),
      'defaultBirdType': defaultBirdType,
      'profileImageUrl': profileImageUrl,
      'farmName': farmName,
      'phoneNumber': phoneNumber,
    };
  }

  static TimeOfDay _timeFromJson(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String _timeToJson(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  factory UserPreferencesModel.fromEntity(UserPreferences entity) {
    return UserPreferencesModel(
      userId: entity.userId,
      defaultCurrency: entity.defaultCurrency,
      language: entity.language,
      themeMode: entity.themeMode,
      dateFormat: entity.dateFormat,
      pushNotifications: entity.pushNotifications,
      emailNotifications: entity.emailNotifications,
      highMortalityAlerts: entity.highMortalityAlerts,
      missingRecordAlerts: entity.missingRecordAlerts,
      mortalityThreshold: entity.mortalityThreshold,
      dailyReportReminderTime: entity.dailyReportReminderTime,
      feedingSchedules: entity.feedingSchedules,
      defaultBirdType: entity.defaultBirdType,
      profileImageUrl: entity.profileImageUrl,
      farmName: entity.farmName,
      phoneNumber: entity.phoneNumber,
    );
  }
}

class FeedingScheduleModel extends FeedingSchedule {
  const FeedingScheduleModel({
    required super.id,
    required super.name,
    required super.time,
    super.enabled,
  });

  factory FeedingScheduleModel.fromJson(Map<String, dynamic> json) {
    return FeedingScheduleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      time: UserPreferencesModel._timeFromJson(json['time'] as String),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'time': UserPreferencesModel._timeToJson(time),
      'enabled': enabled,
    };
  }

  factory FeedingScheduleModel.fromEntity(FeedingSchedule entity) {
    return FeedingScheduleModel(
      id: entity.id,
      name: entity.name,
      time: entity.time,
      enabled: entity.enabled,
    );
  }
}
