import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vaccine_schedule.dart';
import '../entities/vaccination_log.dart';

abstract class VaccinationRepository {
  Future<Either<Failure, List<VaccineSchedule>>> getVaccineSchedules(String batchId);
  Future<Either<Failure, VaccineSchedule>> createVaccineSchedule(VaccineSchedule schedule);
  Future<Either<Failure, VaccineSchedule>> updateVaccineSchedule(VaccineSchedule schedule);
  Future<Either<Failure, void>> deleteVaccineSchedule(String scheduleId);
  
  Future<Either<Failure, List<VaccinationLog>>> getVaccinationLogs(String batchId);
  Future<Either<Failure, VaccinationLog>> logVaccination(VaccinationLog log);
  Future<Either<Failure, VaccinationLog>> updateVaccinationLog(VaccinationLog log);
  Future<Either<Failure, void>> deleteVaccinationLog(String logId);
  
  Future<Either<Failure, List<VaccineSchedule>>> getDefaultSchedules();
  Future<Either<Failure, void>> createSchedulesForBatch(String batchId, String userId);
}
