import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../data/datasourse/auth_remote_datasource.dart';
import '../data/repository/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/register_usecase.dart';
import '../presentation/provider/auth_provider.dart';

class AuthInjection {
  static List<ChangeNotifierProvider> providers = [
    ChangeNotifierProvider<AuthProvider>(
      create: (context) => AuthProvider(
        RegisterUseCase(
          AuthRepositoryImpl(
            AuthRemoteDataSourceImpl(
              client: http.Client(),
            ),
          ),
        ),
      ),
    ),
  ];
} 