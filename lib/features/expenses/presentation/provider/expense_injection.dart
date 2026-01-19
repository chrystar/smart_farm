import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/datasources/expense_remote_datasource.dart';
import '../../data/repository/expense_repository_impl.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/create_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_expenses_by_date_range_usecase.dart';
import '../provider/expense_provider.dart';

class ExpenseInjection {
  static final _supabaseClient = SupabaseService().client;

  static final _remoteDataSource = ExpenseRemoteDataSourceImpl(
    supabaseClient: _supabaseClient,
  );

  static final _repository = ExpenseRepositoryImpl(
    remoteDataSource: _remoteDataSource,
  );

  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(
      create: (_) => ExpenseProvider(
        getExpensesUseCase: GetExpensesUseCase(_repository),
        createExpenseUseCase: CreateExpenseUseCase(_repository),
        deleteExpenseUseCase: DeleteExpenseUseCase(_repository),
        getExpensesByDateRangeUseCase: GetExpensesByDateRangeUseCase(_repository),
        remoteDataSource: _remoteDataSource,
      ),
    ),
  ];
}
