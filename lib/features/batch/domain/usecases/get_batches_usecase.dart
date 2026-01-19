import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/batch.dart';
import '../repository/batch_repository.dart';

class GetBatchesUseCase {
  final BatchRepository repository;

  GetBatchesUseCase(this.repository);

  Future<Either<Failure, List<Batch>>> call(String userId) async {
    return await repository.getBatches(userId);
  }
}
