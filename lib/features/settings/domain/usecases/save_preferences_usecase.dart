import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_preferences.dart';
import '../repository/settings_repository.dart';

class SavePreferencesUseCase {
  final SettingsRepository repository;

  SavePreferencesUseCase(this.repository);

  Future<Either<Failure, void>> call(UserPreferences preferences) {
    return repository.savePreferences(preferences);
  }
}
