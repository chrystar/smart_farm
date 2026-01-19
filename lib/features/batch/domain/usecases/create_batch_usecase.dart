import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/batch.dart';
import '../repository/batch_repository.dart';

class CreateBatchUseCase {
  final BatchRepository repository;

  CreateBatchUseCase(this.repository);

  Future<Either<Failure, Batch>> call({
    required String name,
    required BirdType birdType,
    String? breed,
    required int expectedQuantity,
    double? purchaseCost,
    String? currency,
    required String userId,
  }) async {
    return await repository.createBatch(
      name: name,
      birdType: birdType,
      breed: breed,
      expectedQuantity: expectedQuantity,
      purchaseCost: purchaseCost,
      currency: currency,
      userId: userId,
    );
  }
}
