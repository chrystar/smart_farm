import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repository/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/user_preferences_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;
  final NotificationService notificationService;

  SettingsRepositoryImpl({
    required this.localDataSource,
    required this.notificationService,
  });

  @override
  Future<Either<Failure, UserPreferences>> getPreferences(String userId) async {
    try {
      final preferences = await localDataSource.getPreferences(userId);
      return Right(preferences);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> savePreferences(UserPreferences preferences) async {
    try {
      final model = UserPreferencesModel.fromEntity(preferences);
      await localDataSource.savePreferences(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    required String userId,
    String? farmName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      // Get current preferences
      final currentPrefs = await localDataSource.getPreferences(userId);
      
      // Update with new profile data
      final updatedPrefs = UserPreferencesModel(
        userId: userId,
        defaultCurrency: currentPrefs.defaultCurrency,
        language: currentPrefs.language,
        themeMode: currentPrefs.themeMode,
        dateFormat: currentPrefs.dateFormat,
        pushNotifications: currentPrefs.pushNotifications,
        emailNotifications: currentPrefs.emailNotifications,
        highMortalityAlerts: currentPrefs.highMortalityAlerts,
        missingRecordAlerts: currentPrefs.missingRecordAlerts,
        mortalityThreshold: currentPrefs.mortalityThreshold,
        dailyReportReminderTime: currentPrefs.dailyReportReminderTime,
        feedingSchedules: currentPrefs.feedingSchedules,
        defaultBirdType: currentPrefs.defaultBirdType,
        farmName: farmName ?? currentPrefs.farmName,
        phoneNumber: phoneNumber ?? currentPrefs.phoneNumber,
        profileImageUrl: profileImageUrl ?? currentPrefs.profileImageUrl,
      );

      await localDataSource.savePreferences(updatedPrefs);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> scheduleFeedingNotification(
      FeedingSchedule schedule) async {
    try {
      if (schedule.enabled) {
        await notificationService.scheduleFeedingNotification(schedule);
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelFeedingNotification(String scheduleId) async {
    try {
      await notificationService.cancelFeedingNotification(scheduleId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> scheduleDailyReportReminder(TimeOfDay time) async {
    try {
      await notificationService.scheduleDailyReportReminder(time);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelDailyReportReminder() async {
    try {
      await notificationService.cancelDailyReportReminder();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
