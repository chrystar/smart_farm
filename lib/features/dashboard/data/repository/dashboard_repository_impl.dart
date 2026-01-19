import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../batch/domain/entities/batch.dart';
import '../../../batch/data/datasource/batch_remote_datasource.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repository/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final BatchRemoteDataSource batchRemoteDataSource;

  DashboardRepositoryImpl({required this.batchRemoteDataSource});

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats(String userId) async {
    try {
      final batches = await batchRemoteDataSource.getBatches(userId);
      
      int activeBatches = 0;
      int plannedBatches = 0;
      int completedBatches = 0;
      int totalLiveBirds = 0;
      double totalMortalityRate = 0.0;
      int activeBatchesWithRecords = 0;
      Map<String, double> investmentByCurrency = {};
      List<BatchAlert> alerts = [];
      List<RecentActivity> recentActivities = [];

      for (final batch in batches) {
        // Count by status
        if (batch.status == BatchStatus.active) {
          activeBatches++;
          
          // Get total mortality for this batch
          final totalMortality = await batchRemoteDataSource.getTotalMortality(batch.id);
          totalLiveBirds += batch.getCurrentLiveBirds(totalMortality);
          
          // Calculate mortality rate for active batches
          if (batch.actualQuantity != null && batch.actualQuantity! > 0) {
            final mortalityRate = ((batch.actualQuantity! - batch.getCurrentLiveBirds(totalMortality)) / batch.actualQuantity!) * 100;
            totalMortalityRate += mortalityRate;
            activeBatchesWithRecords++;
          }
        } else if (batch.status == BatchStatus.planned) {
          plannedBatches++;
        } else if (batch.status == BatchStatus.completed) {
          completedBatches++;
        }

        // Aggregate investment by currency
        if (batch.purchaseCost != null && batch.currency != null) {
          investmentByCurrency[batch.currency!] = 
              (investmentByCurrency[batch.currency!] ?? 0) + batch.purchaseCost!;
        }
      }

      // Calculate average mortality rate
      final avgMortalityRate = activeBatchesWithRecords > 0 
          ? totalMortalityRate / activeBatchesWithRecords 
          : 0.0;

      // Generate alerts for active batches
      for (final batch in batches.where((b) => b.status == BatchStatus.active)) {
        final records = await batchRemoteDataSource.getDailyRecords(batch.id);
        
        // Check for high mortality in recent records
        if (records.isNotEmpty) {
          final latestRecord = records.last;
          if (latestRecord.mortalityCount > (batch.actualQuantity ?? 0) * 0.05) {
            final daysSinceStart = batch.getDaysSinceStart() ?? 0;
            alerts.add(BatchAlert(
              batchId: batch.id,
              batchName: batch.name,
              type: AlertType.highMortality,
              message: '${latestRecord.mortalityCount} deaths recorded on Day $daysSinceStart',
              timestamp: latestRecord.date,
            ));
          }

          // Add to recent activities
          final recordsToShow = records.reversed.take(5);
          for (final record in recordsToShow) {
            // Calculate day number based on record date
            final dayNumber = batch.startDate != null
                ? record.date.difference(batch.startDate!).inDays + 1
                : 0;
            recentActivities.add(RecentActivity(
              batchId: batch.id,
              batchName: batch.name,
              dayNumber: dayNumber,
              deaths: record.mortalityCount,
              recordDate: record.date,
            ));
          }
        }

        // Check for missing records (no record for today)
        final today = DateTime.now();
        final hasRecordToday = records.any((r) => 
          r.date.year == today.year && 
          r.date.month == today.month && 
          r.date.day == today.day
        );
        
        if (!hasRecordToday && batch.startDate != null) {
          alerts.add(BatchAlert(
            batchId: batch.id,
            batchName: batch.name,
            type: AlertType.missingRecord,
            message: 'No daily record for today',
            timestamp: DateTime.now(),
          ));
        }
      }

      // Sort recent activities by date (most recent first)
      recentActivities.sort((a, b) => b.recordDate.compareTo(a.recordDate));
      recentActivities = recentActivities.take(10).toList();

      // Sort alerts by timestamp (most recent first)
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return Right(DashboardStats(
        totalActiveBatches: activeBatches,
        totalPlannedBatches: plannedBatches,
        totalCompletedBatches: completedBatches,
        totalLiveBirds: totalLiveBirds,
        averageMortalityRate: avgMortalityRate,
        investmentByCurrency: investmentByCurrency,
        alerts: alerts,
        recentActivities: recentActivities,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BatchPerformanceMetric>>> getBatchPerformanceMetrics(String userId) async {
    try {
      final batches = await batchRemoteDataSource.getBatches(userId);
      final metrics = <BatchPerformanceMetric>[];

      for (final batch in batches.where((b) => b.status == BatchStatus.active)) {
        // Get total mortality for this batch
        final totalMortality = await batchRemoteDataSource.getTotalMortality(batch.id);
        final liveBirds = batch.getCurrentLiveBirds(totalMortality);
        final initialQuantity = batch.actualQuantity ?? 0;
        
        if (initialQuantity > 0) {
          final survivalRate = (liveBirds / initialQuantity) * 100;
          final mortalityRate = 100 - survivalRate;
          final currentDay = batch.getDaysSinceStart() ?? 0;

          metrics.add(BatchPerformanceMetric(
            batchId: batch.id,
            batchName: batch.name,
            currentDay: currentDay,
            survivalRate: survivalRate,
            mortalityRate: mortalityRate,
            liveBirds: liveBirds,
            initialQuantity: initialQuantity,
            currency: batch.currency,
            purchaseCost: batch.purchaseCost,
          ));
        }
      }

      // Sort by mortality rate (highest first) to show problem batches
      metrics.sort((a, b) => b.mortalityRate.compareTo(a.mortalityRate));

      return Right(metrics);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
