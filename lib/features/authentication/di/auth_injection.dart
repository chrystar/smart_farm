import 'package:provider/provider.dart';
import 'package:smart_farm/core/services/supabase_service.dart';
import '../data/datasourse/auth_remote_datasource.dart';
import '../data/repository/auth_repository_impl.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/login_usecase.dart';
import '../presentation/provider/auth_provider.dart';

class AuthInjection {
  static List<ChangeNotifierProvider> providers = [
    ChangeNotifierProvider<AuthProvider>(
      create: (context) => AuthProvider(
        RegisterUseCase(
          AuthRepositoryImpl(
            AuthRemoteDataSourceImpl(
              supabaseService: SupabaseService(),
            ),
          ),
        ),
        LoginUseCase(
          AuthRepositoryImpl(
            AuthRemoteDataSourceImpl(
              supabaseService: SupabaseService(),
            ),
          ),
        ),
      ),
    ),
  ];
}
