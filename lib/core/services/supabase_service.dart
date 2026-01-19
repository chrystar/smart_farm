import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_farm/core/config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  late SupabaseClient _client;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;

  // Get the current authenticated user
  User? get currentUser => _client.auth.currentUser;
  
  // Get the current user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  // Get the current session
  Session? get currentSession => _client.auth.currentSession;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get user data from profiles table
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client
          .from(SupabaseConfig.usersTable)
          .update(data)
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  // Create user profile
  Future<void> createUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client.from(SupabaseConfig.usersTable).insert({
        'id': userId,
        ...data,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ============ BATCH MANAGEMENT ============

  // Create a new batch
  Future<Map<String, dynamic>> createBatch(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(SupabaseConfig.batchesTable)
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get all batches for a user
  Future<List<Map<String, dynamic>>> getBatches(String userId) async {
    try {
      final response = await _client
          .from(SupabaseConfig.batchesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Get a single batch by ID
  Future<Map<String, dynamic>> getBatchById(String batchId) async {
    try {
      final response = await _client
          .from(SupabaseConfig.batchesTable)
          .select()
          .eq('id', batchId)
          .single();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Update a batch
  Future<Map<String, dynamic>> updateBatch(
    String batchId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from(SupabaseConfig.batchesTable)
          .update(data)
          .eq('id', batchId)
          .select()
          .single();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Delete a batch
  Future<void> deleteBatch(String batchId) async {
    try {
      await _client.from(SupabaseConfig.batchesTable).delete().eq('id', batchId);
    } catch (e) {
      rethrow;
    }
  }

  // ============ DAILY RECORDS ============

  // Create a daily record
  Future<Map<String, dynamic>> createDailyRecord(
      Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(SupabaseConfig.dailyRecordsTable)
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get all daily records for a batch
  Future<List<Map<String, dynamic>>> getDailyRecords(String batchId) async {
    try {
      final response = await _client
          .from(SupabaseConfig.dailyRecordsTable)
          .select()
          .eq('batch_id', batchId)
          .order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  // Update a daily record
  Future<Map<String, dynamic>> updateDailyRecord(
    String recordId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from(SupabaseConfig.dailyRecordsTable)
          .update(data)
          .eq('id', recordId)
          .select()
          .single();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Delete a daily record
  Future<void> deleteDailyRecord(String recordId) async {
    try {
      await _client
          .from(SupabaseConfig.dailyRecordsTable)
          .delete()
          .eq('id', recordId);
    } catch (e) {
      rethrow;
    }
  }

  // Get total mortality for a batch
  Future<int> getTotalMortality(String batchId) async {
    try {
      final response = await _client
          .from(SupabaseConfig.dailyRecordsTable)
          .select('mortality_count')
          .eq('batch_id', batchId);

      if (response.isEmpty) return 0;

      int total = 0;
      for (var record in response) {
        total += (record['mortality_count'] as int?) ?? 0;
      }
      return total;
    } catch (e) {
      rethrow;
    }
  }

}

