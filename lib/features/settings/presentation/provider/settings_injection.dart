import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/repository/settings_repository_impl.dart';
import '../../domain/usecases/get_preferences_usecase.dart';
import '../../domain/usecases/save_preferences_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/notification_usecases.dart';
import '../provider/settings_provider.dart';

class SettingsInjection {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(
      create: (_) {
        // This will be initialized asynchronously in main
        return SettingsProvider(
          getPreferencesUseCase: GetPreferencesUseCase(_repository),
          savePreferencesUseCase: SavePreferencesUseCase(_repository),
          updateProfileUseCase: UpdateProfileUseCase(_repository),
          scheduleFeedingNotificationUseCase: ScheduleFeedingNotificationUseCase(_repository),
          cancelFeedingNotificationUseCase: CancelFeedingNotificationUseCase(_repository),
          scheduleDailyReportReminderUseCase: ScheduleDailyReportReminderUseCase(_repository),
          cancelDailyReportReminderUseCase: CancelDailyReportReminderUseCase(_repository),
        );
      },
    ),
  ];

  static late final SettingsRepositoryImpl _repository;

  static Future<void> initialize() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final notificationService = NotificationService();
    await notificationService.initialize();

    final localDataSource = SettingsLocalDataSourceImpl(
      sharedPreferences: sharedPreferences,
    );

    _repository = SettingsRepositoryImpl(
      localDataSource: localDataSource,
      notificationService: notificationService,
    );
  }
}
