import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String name,
    required String phoneNumber,
    required String password,
  }) {
    return repository.register(
      name: name,
      phoneNumber: phoneNumber,
      password: password,
    );
  }
} 