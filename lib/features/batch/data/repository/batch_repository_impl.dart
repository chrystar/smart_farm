import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/daily_record.dart';
import '../../domain/repository/batch_repository.dart';
import '../datasource/batch_remote_datasource.dart';

class BatchRepositoryImpl implements BatchRepository {
  final BatchRemoteDataSource remoteDataSource;

  BatchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Batch>> createBatch({
    required String name,
    required BirdType birdType,
    String? breed,
    required int expectedQuantity,
    double? purchaseCost,
    String? currency,
    required String userId,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'name': name,
        'bird_type': _birdTypeToString(birdType),
        'breed': breed,
        'expected_quantity': expectedQuantity,
        'purchase_cost': purchaseCost,
        'currency': currency,
        'user_id': userId,
        'status': 'planned',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final batch = await remoteDataSource.createBatch(data);
      return Right(batch);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Batch>>> getBatches(String userId) async {
    try {
      final batches = await remoteDataSource.getBatches(userId);
      return Right(batches);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Batch>> getBatchById(String batchId) async {
    try {
      final batch = await remoteDataSource.getBatchById(batchId);
      return Right(batch);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Batch>> startBatch({
    required String batchId,
    required int actualQuantity,
    required DateTime startDate,
  }) async {
    try {
      final data = {
        'actual_quantity': actualQuantity,
        'start_date': startDate.toIso8601String(),
        'status': 'active',
        'updated_at': DateTime.now().toIso8601String(),
      };

      final batch = await remoteDataSource.updateBatch(batchId, data);
      return Right(batch);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Batch>> completeBatch({
    required String batchId,
    required DateTime endDate,
  }) async {
    try {
      final data = {
        'end_date': endDate.toIso8601String(),
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      };

      final batch = await remoteDataSource.updateBatch(batchId, data);
      return Right(batch);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Batch>> updateBatch(
      String batchId, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      final batch = await remoteDataSource.updateBatch(batchId, data);
      return Right(batch);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBatch(String batchId) async {
    try {
      await remoteDataSource.deleteBatch(batchId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DailyRecord>> createDailyRecord({
    required String batchId,
    required DateTime date,
    required int mortalityCount,
    String? notes,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'batch_id': batchId,
        'date': date.toIso8601String().split('T')[0], // Date only
        'mortality_count': mortalityCount,
        'notes': notes,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final record = await remoteDataSource.createDailyRecord(data);
      return Right(record);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DailyRecord>>> getDailyRecords(
      String batchId) async {
    try {
      final records = await remoteDataSource.getDailyRecords(batchId);
      return Right(records);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DailyRecord>> updateDailyRecord(
      String recordId, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      final record = await remoteDataSource.updateDailyRecord(recordId, data);
      return Right(record);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDailyRecord(String recordId) async {
    try {
      await remoteDataSource.deleteDailyRecord(recordId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getTotalMortality(String batchId) async {
    try {
      final total = await remoteDataSource.getTotalMortality(batchId);
      return Right(total);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  String _birdTypeToString(BirdType type) {
    switch (type) {
      case BirdType.broiler:
        return 'broiler';
      case BirdType.layer:
        return 'layer';
    }
  }
}
