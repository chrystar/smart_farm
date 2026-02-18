import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/vaccine_schedule.dart';
import '../../domain/entities/vaccination_log.dart';
import '../../domain/repositories/vaccination_repository.dart';
import '../datasources/vaccination_remote_datasource.dart';
import '../models/vaccine_schedule_model.dart';
import '../models/vaccination_log_model.dart';

class VaccinationRepositoryImpl implements VaccinationRepository {
  final VaccinationRemoteDataSource remoteDataSource;

  VaccinationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<VaccineSchedule>>> getVaccineSchedules(String batchId) async {
    try {
      final schedules = await remoteDataSource.getVaccineSchedules(batchId);
      return Right(schedules);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VaccineSchedule>> createVaccineSchedule(VaccineSchedule schedule) async {
    try {
      final model = VaccineScheduleModel.fromEntity(schedule);
      final result = await remoteDataSource.createVaccineSchedule(model.toJson());
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VaccineSchedule>> updateVaccineSchedule(VaccineSchedule schedule) async {
    try {
      final model = VaccineScheduleModel.fromEntity(schedule);
      final result = await remoteDataSource.updateVaccineSchedule(schedule.id, model.toJson());
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVaccineSchedule(String scheduleId) async {
    try {
      await remoteDataSource.deleteVaccineSchedule(scheduleId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VaccinationLog>>> getVaccinationLogs(String batchId) async {
    try {
      final logs = await remoteDataSource.getVaccinationLogs(batchId);
      return Right(logs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VaccinationLog>> logVaccination(VaccinationLog log) async {
    try {
      final model = VaccinationLogModel.fromEntity(log);
      final result = await remoteDataSource.logVaccination(model.toJson());
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VaccinationLog>> updateVaccinationLog(VaccinationLog log) async {
    try {
      final model = VaccinationLogModel.fromEntity(log);
      final result = await remoteDataSource.updateVaccinationLog(log.id, model.toJson());
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVaccinationLog(String logId) async {
    try {
      await remoteDataSource.deleteVaccinationLog(logId);
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VaccineSchedule>>> getDefaultSchedules() async {
    try {
      final schedules = await remoteDataSource.getDefaultSchedules();
      return Right(schedules);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createSchedulesForBatch(String batchId, String userId) async {
    try {
      await remoteDataSource.createSchedulesForBatch(batchId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
