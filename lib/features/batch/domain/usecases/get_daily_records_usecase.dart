import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_record.dart';
import '../repository/batch_repository.dart';

class GetDailyRecordsUseCase {
  final BatchRepository repository;

  GetDailyRecordsUseCase(this.repository);

  Future<Either<Failure, List<DailyRecord>>> call(String batchId) async {
    return await repository.getDailyRecords(batchId);
  }
}
