import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_preferences.dart';
import '../repository/settings_repository.dart';

class GetPreferencesUseCase {
  final SettingsRepository repository;

  GetPreferencesUseCase(this.repository);

  Future<Either<Failure, UserPreferences>> call(String userId) {
    return repository.getPreferences(userId);
  }
}
