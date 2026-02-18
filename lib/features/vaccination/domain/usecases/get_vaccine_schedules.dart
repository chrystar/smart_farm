import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vaccine_schedule.dart';
import '../repositories/vaccination_repository.dart';

class GetVaccineSchedules {
  final VaccinationRepository repository;

  GetVaccineSchedules(this.repository);

  Future<Either<Failure, List<VaccineSchedule>>> call(String batchId) {
    return repository.getVaccineSchedules(batchId);
  }
}
