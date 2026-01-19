import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats.dart';
import '../repository/dashboard_repository.dart';

class GetBatchPerformanceMetricsUseCase {
  final DashboardRepository repository;

  GetBatchPerformanceMetricsUseCase(this.repository);

  Future<Either<Failure, List<BatchPerformanceMetric>>> call(String userId) {
    return repository.getBatchPerformanceMetrics(userId);
  }
}
