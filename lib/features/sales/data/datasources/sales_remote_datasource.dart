import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';

class SalesRemoteDataSource {
  final SupabaseClient supabaseClient;

  SalesRemoteDataSource(this.supabaseClient);

  Future<SaleModel> recordSale(Map<String, dynamic> saleData) async {
    try {
      debugPrint('Inserting sale data: $saleData');
      final response = await supabaseClient
          .from('sales')
          .insert(saleData)
          .select()
          .single();
      debugPrint('Sale inserted successfully: $response');
      return SaleModel.fromJson(response);
    } catch (e) {
      debugPrint('Error recording sale: $e');
      throw Exception('Failed to record sale: $e');
    }
  }

  Future<List<SaleModel>> getSales(String userId) async {
    try {
      final response = await supabaseClient
          .from('sales')
          .select()
          .eq('user_id', userId)
          .order('sale_date', ascending: false);

      return (response as List)
          .map((e) => SaleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch sales: $e');
    }
  }

  Future<List<SaleModel>> getBatchSales(String batchId) async {
    try {
      final response = await supabaseClient
          .from('sales')
          .select()
          .eq('batch_id', batchId)
          .order('sale_date', ascending: false);

      return (response as List)
          .map((e) => SaleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch batch sales: $e');
    }
  }

  Future<void> updatePaymentStatus(String saleId, String status) async {
    try {
      await supabaseClient
          .from('sales')
          .update({'payment_status': status})
          .eq('id', saleId);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  Future<void> deleteSale(String saleId) async {
    try {
      await supabaseClient.from('sales').delete().eq('id', saleId);
    } catch (e) {
      throw Exception('Failed to delete sale: $e');
    }
  }

  Future<void> createSaleGroup(
      String groupTitle, List<String> saleIds) async {
    try {
      final groupId = DateTime.now().millisecondsSinceEpoch.toString();

      await supabaseClient.from('sales').update({
        'group_id': groupId,
        'group_title': groupTitle,
      }).inFilter('id', saleIds);
    } catch (e) {
      throw Exception('Failed to create sale group: $e');
    }
  }
}
