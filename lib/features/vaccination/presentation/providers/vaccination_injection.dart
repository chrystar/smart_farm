import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../../../core/services/supabase_service.dart';
import '../../data/datasources/vaccination_remote_datasource.dart';
import '../../data/repositories/vaccination_repository_impl.dart';
import '../providers/vaccination_provider.dart';

class VaccinationInjection {
  static final _supabaseClient = SupabaseService().client;

  static final _remoteDataSource = VaccinationRemoteDataSourceImpl(
    supabaseClient: _supabaseClient,
  );

  static final _repository = VaccinationRepositoryImpl(
    remoteDataSource: _remoteDataSource,
  );

  static List<SingleChildWidget> providers = [
    ChangeNotifierProvider(
      create: (_) => VaccinationProvider(
        repository: _repository,
      ),
    ),
  ];
}

void setupVaccinationInjection() {
  // This function can be removed as injection is handled via VaccinationInjection.providers
  // Kept for backward compatibility if needed
}
