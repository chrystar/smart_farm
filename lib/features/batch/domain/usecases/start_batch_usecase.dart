import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/batch.dart';
import '../repository/batch_repository.dart';

class StartBatchUseCase {
  final BatchRepository repository;

  StartBatchUseCase(this.repository);

  Future<Either<Failure, Batch>> call({
    required String batchId,
    required int actualQuantity,
    required DateTime startDate,
  }) async {
    return await repository.startBatch(
      batchId: batchId,
      actualQuantity: actualQuantity,
      startDate: startDate,
    );
  }
}
