import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../batch/data/datasource/batch_remote_datasource.dart';
import '../../data/repository/dashboard_repository_impl.dart';
import '../../domain/usecases/get_dashboard_stats_usecase.dart';
import '../../domain/usecases/get_batch_performance_metrics_usecase.dart';
import '../provider/dashboard_provider.dart';

class DashboardInjection {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(
      create: (_) {
        final supabaseService = SupabaseService();
        final batchDataSource = BatchRemoteDataSourceImpl(
          supabaseService: supabaseService,
        );
        final repository = DashboardRepositoryImpl(
          batchRemoteDataSource: batchDataSource,
        );

        return DashboardProvider(
          getDashboardStatsUseCase: GetDashboardStatsUseCase(repository),
          getBatchPerformanceMetricsUseCase: GetBatchPerformanceMetricsUseCase(repository),
        );
      },
    ),
  ];
}
