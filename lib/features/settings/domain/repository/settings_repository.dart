import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_preferences.dart';

abstract class SettingsRepository {
  Future<Either<Failure, UserPreferences>> getPreferences(String userId);
  Future<Either<Failure, void>> savePreferences(UserPreferences preferences);
  Future<Either<Failure, void>> updateProfile({
    required String userId,
    String? farmName,
    String? phoneNumber,
    String? profileImageUrl,
  });
  Future<Either<Failure, void>> scheduleFeedingNotification(FeedingSchedule schedule);
  Future<Either<Failure, void>> cancelFeedingNotification(String scheduleId);
  Future<Either<Failure, void>> scheduleDailyReportReminder(TimeOfDay time);
  Future<Either<Failure, void>> cancelDailyReportReminder();
}
