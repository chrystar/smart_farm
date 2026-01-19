import '../../../../core/services/supabase_service.dart';
import '../models/batch_model.dart';
import '../models/daily_record_model.dart';

abstract class BatchRemoteDataSource {
  Future<BatchModel> createBatch(Map<String, dynamic> data);
  Future<List<BatchModel>> getBatches(String userId);
  Future<BatchModel> getBatchById(String batchId);
  Future<BatchModel> updateBatch(String batchId, Map<String, dynamic> data);
  Future<void> deleteBatch(String batchId);
  Future<DailyRecordModel> createDailyRecord(Map<String, dynamic> data);
  Future<List<DailyRecordModel>> getDailyRecords(String batchId);
  Future<DailyRecordModel> updateDailyRecord(
      String recordId, Map<String, dynamic> data);
  Future<void> deleteDailyRecord(String recordId);
  Future<int> getTotalMortality(String batchId);

}

class BatchRemoteDataSourceImpl implements BatchRemoteDataSource {
  final SupabaseService supabaseService;

  BatchRemoteDataSourceImpl({required this.supabaseService});

  @override
  Future<BatchModel> createBatch(Map<String, dynamic> data) async {
    try {
      final response = await supabaseService.createBatch(data);
      return BatchModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create batch: $e');
    }
  }

  @override
  Future<List<BatchModel>> getBatches(String userId) async {
    try {
      final response = await supabaseService.getBatches(userId);
      return response.map((json) => BatchModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch batches: $e');
    }
  }

  @override
  Future<BatchModel> getBatchById(String batchId) async {
    try {
      final response = await supabaseService.getBatchById(batchId);
      return BatchModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch batch: $e');
    }
  }

  @override
  Future<BatchModel> updateBatch(
      String batchId, Map<String, dynamic> data) async {
    try {
      final response = await supabaseService.updateBatch(batchId, data);
      return BatchModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update batch: $e');
    }
  }

  @override
  Future<void> deleteBatch(String batchId) async {
    try {
      await supabaseService.deleteBatch(batchId);
    } catch (e) {
      throw Exception('Failed to delete batch: $e');
    }
  }

  @override
  Future<DailyRecordModel> createDailyRecord(Map<String, dynamic> data) async {
    try {
      final response = await supabaseService.createDailyRecord(data);
      return DailyRecordModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create daily record: $e');
    }
  }

  @override
  Future<List<DailyRecordModel>> getDailyRecords(String batchId) async {
    try {
      final response = await supabaseService.getDailyRecords(batchId);
      return response.map((json) => DailyRecordModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch daily records: $e');
    }
  }

  @override
  Future<DailyRecordModel> updateDailyRecord(
      String recordId, Map<String, dynamic> data) async {
    try {
      final response = await supabaseService.updateDailyRecord(recordId, data);
      return DailyRecordModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update daily record: $e');
    }
  }

  @override
  Future<void> deleteDailyRecord(String recordId) async {
    try {
      await supabaseService.deleteDailyRecord(recordId);
    } catch (e) {
      throw Exception('Failed to delete daily record: $e');
    }
  }

  @override
  Future<int> getTotalMortality(String batchId) async {
    try {
      return await supabaseService.getTotalMortality(batchId);
    } catch (e) {
      throw Exception('Failed to fetch total mortality: $e');
    }
  }

}
