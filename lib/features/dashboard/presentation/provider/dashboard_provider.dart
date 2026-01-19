import 'package:flutter/material.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';
import '../../domain/usecases/get_batch_performance_metrics_usecase.dart';

class DashboardProvider with ChangeNotifier {
  final GetDashboardStatsUseCase getDashboardStatsUseCase;
  final GetBatchPerformanceMetricsUseCase getBatchPerformanceMetricsUseCase;

  DashboardProvider({
    required this.getDashboardStatsUseCase,
    required this.getBatchPerformanceMetricsUseCase,
  });

  DashboardStats? _stats;
  List<BatchPerformanceMetric>? _performanceMetrics;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardStats? get stats => _stats;
  List<BatchPerformanceMetric>? get performanceMetrics => _performanceMetrics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDashboard(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load dashboard stats
      final statsResult = await getDashboardStatsUseCase(userId);
      statsResult.fold(
        (failure) => _errorMessage = failure.toString(),
        (stats) => _stats = stats,
      );

      // Load performance metrics
      final metricsResult = await getBatchPerformanceMetricsUseCase(userId);
      metricsResult.fold(
        (failure) => _errorMessage = failure.toString(),
        (metrics) => _performanceMetrics = metrics,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh(String userId) async {
    await loadDashboard(userId);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
