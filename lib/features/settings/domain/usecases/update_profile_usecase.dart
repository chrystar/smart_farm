import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repository/settings_repository.dart';

class UpdateProfileUseCase {
  final SettingsRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    String? farmName,
    String? phoneNumber,
    String? profileImageUrl,
  }) {
    return repository.updateProfile(
      userId: userId,
      farmName: farmName,
      phoneNumber: phoneNumber,
      profileImageUrl: profileImageUrl,
    );
  }
}
