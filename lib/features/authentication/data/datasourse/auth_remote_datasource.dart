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
      print('═══════════════════════════════════════════');
      print('🔍 REGISTRATION STARTING');
      print('📧 Email: $email');
      print('═══════════════════════════════════════════');
      
      // Step 1: Sign up user with Supabase Auth
      print('\n[Step 1/2] Creating Supabase Auth user...');
      final authResponse = await supabaseService.signUp(
        email: email,
        password: password,
        userData: {
          'name': name,
          'email': email,
          'role': 'farmer',
        },
      );

      final userId = authResponse.user?.id;
      if (userId == null) {
        throw Exception('User creation failed - no userId returned from Supabase Auth');
      }
      print('✅ Auth user created successfully');
      print('   User ID: $userId');

      // Step 2: Create user profile in profiles table
      print('\n[Step 2/2] Creating user profile in database...');
      try {
        await supabaseService.createUserProfile(userId, {
          'name': name,
          'email': email,
          'phone_number': '', // Empty phone number - can be updated later
        });
        print('✅ User profile created successfully');
      } catch (profileError) {
        print('❌ PROFILE CREATION FAILED!');
        print('   Error: $profileError');
        print('\n📝 POSSIBLE CAUSES:');
        print('   1. Database schema mismatch');
        print('   2. RLS policy blocking insert');
        print('   3. Required fields not provided');
        print('\n🔧 TO FIX:');
        print('   1. Check Supabase profiles table schema');
        print('   2. Ensure all required fields are provided');
        print('   3. Check RLS policies');
        rethrow;
      }

      print('\n═══════════════════════════════════════════');
      print('✅ REGISTRATION SUCCESSFUL!');
      print('═══════════════════════════════════════════\n');
      
      return UserModel(
        id: userId,
        name: name,
        email: email,
      );
    } on Exception catch (e) {
      print('\n❌ REGISTRATION ERROR:');
      print('   $e');
      rethrow;
    } catch (e) {
      print('\n❌ UNEXPECTED ERROR:');
      print('   $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('═══════════════════════════════════════════');
      print('🔍 LOGIN STARTING');
      print('📧 Email: $email');
      print('═══════════════════════════════════════════');
      
      print('\n📝 Step 1: Authenticating with Supabase...');
      final authResponse = await supabaseService.signIn(
        email: email,
        password: password,
      );

      final userId = authResponse.user?.id;
      final sessionToken = authResponse.session?.accessToken;
      final authEmail = authResponse.user?.email;
      
      print('✅ Step 1 Complete: Authentication successful');
      print('   User ID: $userId');
      print('   Token: ${sessionToken?.substring(0, 20)}...');

      if (userId == null || sessionToken == null) {
        throw Exception('Login failed: Missing user ID or token');
      }

      print('\n📝 Step 2: Fetching user profile from profiles table...');
      // Check user role from profiles table using id (profiles.id references auth.users.id)
      final profileResponse = await supabaseService.client
          .from('profiles')
          .select('role, name, email')
          .eq('id', userId)  // profiles.id references auth.users.id
          .maybeSingle();
      
      print('   Profile Response: $profileResponse');
      
      // For now, only allowing 'farmer' role in this app
      // Vets should use the vet_app instead
      if (profileResponse != null && profileResponse['role'] == 'vet') {
        print('❌ Access denied: User is a vet');
        // Sign out the vet user
        await supabaseService.signOut();
        throw Exception('Access denied. This app is for farmers only. Please use the Vet app.');
      }

      print('✅ Step 2 Complete: Profile fetched');
      print('   Name: ${profileResponse?['name']}');
      print('   Email: ${profileResponse?['email']}');
      print('   Role: ${profileResponse?['role']}');

      print('\n✅ LOGIN SUCCESSFUL');
      print('═══════════════════════════════════════════\n');

      return {
        'token': sessionToken,
        'user': {
          'id': userId,
          'name': profileResponse?['name'] ?? '',
          'email': profileResponse?['email'] ?? authEmail ?? '',
        }
      };
    } on Exception catch (e) {
      print('\n❌ LOGIN ERROR:');
      print('   $e');
      print('═══════════════════════════════════════════\n');
      rethrow;
    } catch (e) {
      print('\n❌ UNEXPECTED LOGIN ERROR:');
      print('   $e');
      print('═══════════════════════════════════════════\n');
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
