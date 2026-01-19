import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_record.dart';
import '../repository/batch_repository.dart';

class CreateDailyRecordUseCase {
  final BatchRepository repository;

  CreateDailyRecordUseCase(this.repository);

  Future<Either<Failure, DailyRecord>> call({
    required String batchId,
    required DateTime date,
    required int mortalityCount,
    String? notes,
  }) async {
    return await repository.createDailyRecord(
      batchId: batchId,
      date: date,
      mortalityCount: mortalityCount,
      notes: notes,
    );
  }
}
