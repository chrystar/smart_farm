import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_preferences.dart';
import '../repository/settings_repository.dart';

class ScheduleFeedingNotificationUseCase {
  final SettingsRepository repository;

  ScheduleFeedingNotificationUseCase(this.repository);

  Future<Either<Failure, void>> call(FeedingSchedule schedule) {
    return repository.scheduleFeedingNotification(schedule);
  }
}

class CancelFeedingNotificationUseCase {
  final SettingsRepository repository;

  CancelFeedingNotificationUseCase(this.repository);

  Future<Either<Failure, void>> call(String scheduleId) {
    return repository.cancelFeedingNotification(scheduleId);
  }
}

class ScheduleDailyReportReminderUseCase {
  final SettingsRepository repository;

  ScheduleDailyReportReminderUseCase(this.repository);

  Future<Either<Failure, void>> call(TimeOfDay time) {
    return repository.scheduleDailyReportReminder(time);
  }
}

class CancelDailyReportReminderUseCase {
  final SettingsRepository repository;

  CancelDailyReportReminderUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.cancelDailyReportReminder();
  }
}
