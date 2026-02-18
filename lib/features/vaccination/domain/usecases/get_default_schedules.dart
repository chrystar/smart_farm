import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vaccine_schedule.dart';
import '../repositories/vaccination_repository.dart';

class GetDefaultSchedules {
  final VaccinationRepository repository;

  GetDefaultSchedules(this.repository);

  Future<Either<Failure, List<VaccineSchedule>>> call() {
    return repository.getDefaultSchedules();
  }
}
