import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vaccination_log.dart';
import '../repositories/vaccination_repository.dart';

class LogVaccination {
  final VaccinationRepository repository;

  LogVaccination(this.repository);

  Future<Either<Failure, VaccinationLog>> call(VaccinationLog log) {
    return repository.logVaccination(log);
  }
}
