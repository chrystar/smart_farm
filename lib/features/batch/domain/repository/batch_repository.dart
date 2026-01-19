import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/daily_record.dart';

abstract class BatchRepository {
  Future<Either<Failure, Batch>> createBatch({
    required String name,
    required BirdType birdType,
    String? breed,
    required int expectedQuantity,
    double? purchaseCost,
    String? currency,
    required String userId,
  });

  Future<Either<Failure, List<Batch>>> getBatches(String userId);
  Future<Either<Failure, Batch>> getBatchById(String batchId);

  Future<Either<Failure, Batch>> startBatch({
    required String batchId,
    required int actualQuantity,
    required DateTime startDate,
  });

  Future<Either<Failure, Batch>> completeBatch({
    required String batchId,
    required DateTime endDate,
  });

  Future<Either<Failure, Batch>> updateBatch(
      String batchId, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteBatch(String batchId);

  Future<Either<Failure, DailyRecord>> createDailyRecord({
    required String batchId,
    required DateTime date,
    required int mortalityCount,
    String? notes,
  });

  Future<Either<Failure, List<DailyRecord>>> getDailyRecords(String batchId);

  Future<Either<Failure, DailyRecord>> updateDailyRecord(
      String recordId, Map<String, dynamic> data);

  Future<Either<Failure, void>> deleteDailyRecord(String recordId);
  Future<Either<Failure, int>> getTotalMortality(String batchId);

}
