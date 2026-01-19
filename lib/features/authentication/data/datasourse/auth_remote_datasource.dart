import 'package:smart_farm/core/services/supabase_service.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });

  Future<UserModel> getUserProfile(String userId);

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseService supabaseService;

  AuthRemoteDataSourceImpl({
    required this.supabaseService,
  });

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Sign up user with email (using phoneNumber as email for now)
      final authResponse = await supabaseService.signUp(
        email: email,
        password: password,
        userData: {
          'name': name,
          'email': email,
        },
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        throw Exception('Failed to register user');
      }

      // Create user profile in database
      await supabaseService.createUserProfile(userId, {
        'name': name,
        'email': email,
      });

      return UserModel(
        id: userId,
        name: name,
        email: email,
      );
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await supabaseService.signIn(
        email: email,
        password: password,
      );

      final userId = authResponse.user?.id;
      final sessionToken = authResponse.session?.accessToken;
      final authEmail = authResponse.user?.email;

      if (userId == null || sessionToken == null) {
        throw Exception('Login failed');
      }

      // Fetch user profile
      final userProfile = await supabaseService.getUserProfile(userId);

      return {
        'token': sessionToken,
        'user': {
          'id': userId,
          'name': userProfile?['name'] ?? '',
          'email': userProfile?['email'] ?? authEmail ?? '',
        }
      };
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final profile = await supabaseService.getUserProfile(userId);
      return UserModel(
        id: userId,
        name: profile?['name'] ?? '',
        email: profile?['email'] ?? '',
      );
    } catch (e) {
      throw Exception('Failed to fetch user profile: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseService.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }
}
