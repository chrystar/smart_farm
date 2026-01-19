import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/datasource/batch_remote_datasource.dart';
import '../../data/repository/batch_repository_impl.dart';
import '../../domain/usecases/create_batch_usecase.dart';
import '../../domain/usecases/create_daily_record_usecase.dart';
import '../../domain/usecases/delete_batch_usecase.dart';
import '../../domain/usecases/get_batches_usecase.dart';
import '../../domain/usecases/get_daily_records_usecase.dart';
import '../../domain/usecases/get_total_mortality_usecase.dart';
import '../../domain/usecases/start_batch_usecase.dart';
import 'batch_provider.dart';

class BatchInjection {
  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(
      create: (_) {
        final supabaseService = SupabaseService();
        final dataSource = BatchRemoteDataSourceImpl(
          supabaseService: supabaseService,
        );
        final repository = BatchRepositoryImpl(
          remoteDataSource: dataSource,
        );

        return BatchProvider(
          createBatchUseCase: CreateBatchUseCase(repository),
          getBatchesUseCase: GetBatchesUseCase(repository),
          startBatchUseCase: StartBatchUseCase(repository),
          deleteBatchUseCase: DeleteBatchUseCase(repository),
          createDailyRecordUseCase: CreateDailyRecordUseCase(repository),
          getDailyRecordsUseCase: GetDailyRecordsUseCase(repository),
          getTotalMortalityUseCase: GetTotalMortalityUseCase(repository),
        );
      },
    ),
  ];
}
