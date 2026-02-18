import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vaccine_schedule.dart';
import '../repositories/vaccination_repository.dart';

class CreateVaccineSchedule {
  final VaccinationRepository repository;

  CreateVaccineSchedule(this.repository);

  Future<Either<Failure, VaccineSchedule>> call(VaccineSchedule schedule) {
    return repository.createVaccineSchedule(schedule);
  }
}
