import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalActiveBatches;
  final int totalPlannedBatches;
  final int totalCompletedBatches;
  final int totalLiveBirds;
  final double averageMortalityRate;
  final Map<String, double> investmentByCurrency;
  final List<BatchAlert> alerts;
  final List<RecentActivity> recentActivities;

  const DashboardStats({
    required this.totalActiveBatches,
    required this.totalPlannedBatches,
    required this.totalCompletedBatches,
    required this.totalLiveBirds,
    required this.averageMortalityRate,
    required this.investmentByCurrency,
    required this.alerts,
    required this.recentActivities,
  });

  int get totalBatches =>
      totalActiveBatches + totalPlannedBatches + totalCompletedBatches;

  double get totalInvestment =>
      investmentByCurrency.values.fold(0.0, (sum, amount) => sum + amount);

  @override
  List<Object?> get props => [
        totalActiveBatches,
        totalPlannedBatches,
        totalCompletedBatches,
        totalLiveBirds,
        averageMortalityRate,
        investmentByCurrency,
        alerts,
        recentActivities,
      ];
}

class BatchAlert extends Equatable {
  final String batchId;
  final String batchName;
  final AlertType type;
  final String message;
  final DateTime timestamp;

  const BatchAlert({
    required this.batchId,
    required this.batchName,
    required this.type,
    required this.message,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [batchId, batchName, type, message, timestamp];
}

enum AlertType {
  highMortality,
  missingRecord,
  lowSurvivalRate,
}

class RecentActivity extends Equatable {
  final String batchId;
  final String batchName;
  final int dayNumber;
  final int deaths;
  final DateTime recordDate;

  const RecentActivity({
    required this.batchId,
    required this.batchName,
    required this.dayNumber,
    required this.deaths,
    required this.recordDate,
  });

  @override
  List<Object?> get props => [batchId, batchName, dayNumber, deaths, recordDate];
}

class BatchPerformanceMetric extends Equatable {
  final String batchId;
  final String batchName;
  final int currentDay;
  final double survivalRate;
  final double mortalityRate;
  final int liveBirds;
  final int initialQuantity;
  final String? currency;
  final double? purchaseCost;

  const BatchPerformanceMetric({
    required this.batchId,
    required this.batchName,
    required this.currentDay,
    required this.survivalRate,
    required this.mortalityRate,
    required this.liveBirds,
    required this.initialQuantity,
    this.currency,
    this.purchaseCost,
  });

  double get costPerBird {
    if (purchaseCost == null || initialQuantity == 0) return 0.0;
    return purchaseCost! / initialQuantity;
  }

  double get costPerLiveBird {
    if (purchaseCost == null || liveBirds == 0) return 0.0;
    return purchaseCost! / liveBirds;
  }

  @override
  List<Object?> get props => [
        batchId,
        batchName,
        currentDay,
        survivalRate,
        mortalityRate,
        liveBirds,
        initialQuantity,
        currency,
        purchaseCost,
      ];
}
