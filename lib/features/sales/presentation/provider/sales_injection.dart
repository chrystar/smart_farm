import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../data/datasources/sales_remote_datasource.dart';
import '../../data/repository/sales_repository_impl.dart';
import '../../domain/usecases/sales_usecases.dart';
import 'sales_provider.dart';

class SalesInjection {
  static final _supabaseClient = SupabaseService().client;
  static final _offlineSyncService = OfflineSyncService();

  static final _remoteDataSource = SalesRemoteDataSource(_supabaseClient, _offlineSyncService);

  static final _repository = SalesRepositoryImpl(_remoteDataSource);

  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(
      create: (_) => SalesProvider(
        recordSaleUseCase: RecordSaleUseCase(_repository),
        getSalesUseCase: GetSalesUseCase(_repository),
        getBatchSalesUseCase: GetBatchSalesUseCase(_repository),
        updatePaymentStatusUseCase: UpdatePaymentStatusUseCase(_repository),
        deleteSaleUseCase: DeleteSaleUseCase(_repository),
        createSaleGroupUseCase: CreateSaleGroupUseCase(_repository),
      ),
    ),
  ];
}
