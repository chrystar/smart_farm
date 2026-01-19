import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repository/batch_repository.dart';

class GetTotalMortalityUseCase {
  final BatchRepository repository;

  GetTotalMortalityUseCase(this.repository);

  Future<Either<Failure, int>> call(String batchId) async {
    return await repository.getTotalMortality(batchId);
  }
}
