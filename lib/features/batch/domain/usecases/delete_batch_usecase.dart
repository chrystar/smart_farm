import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repository/batch_repository.dart';

class DeleteBatchUseCase {
  final BatchRepository repository;

  DeleteBatchUseCase(this.repository);

  Future<Either<Failure, void>> call(String batchId) async {
    return await repository.deleteBatch(batchId);
  }
}
