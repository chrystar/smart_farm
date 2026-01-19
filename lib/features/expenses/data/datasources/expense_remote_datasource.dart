import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';

abstract class ExpenseRemoteDataSource {
  Future<List<ExpenseModel>> getExpenses(String userId);
  Future<List<ExpenseModel>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<ExpenseModel>> getExpensesByBatch(String userId, String batchId);
  Future<ExpenseModel> getExpenseById(String expenseId);
  Future<ExpenseModel> createExpense(ExpenseModel expense);
  Future<ExpenseModel> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String expenseId);
  Future<void> createExpenseGroup(String groupTitle, List<String> expenseIds);
  Future<void> updateExpenseGroup({
    required String expenseId,
    String? groupId,
    String? groupTitle,
  });
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final SupabaseClient supabaseClient;

  ExpenseRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<ExpenseModel>> getExpenses(String userId) async {
    try {
      final response = await supabaseClient
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => ExpenseModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  @override
  Future<List<ExpenseModel>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await supabaseClient
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);

      return (response as List)
          .map((json) => ExpenseModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses by date range: $e');
    }
  }

  @override
  Future<List<ExpenseModel>> getExpensesByBatch(
    String userId,
    String batchId,
  ) async {
    try {
      final response = await supabaseClient
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .eq('batch_id', batchId)
          .order('date', ascending: false);

      return (response as List)
          .map((json) => ExpenseModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch batch expenses: $e');
    }
  }

  @override
  Future<ExpenseModel> getExpenseById(String expenseId) async {
    try {
      final response = await supabaseClient
          .from('expenses')
          .select()
          .eq('id', expenseId)
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch expense: $e');
    }
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    try {
      final data = {
        'user_id': expense.userId,
        'amount': expense.amount,
        'currency': expense.currency,
        'category': expense.category.name,
        'custom_category': expense.customCategory,
        'description': expense.description,
        'date': expense.date.toIso8601String(),
        'batch_id': expense.batchId,
      };

      final response = await supabaseClient
          .from('expenses')
          .insert(data)
          .select()
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    try {
      final data = {
        'amount': expense.amount,
        'currency': expense.currency,
        'category': expense.category.name,
        'custom_category': expense.customCategory,
        'description': expense.description,
        'date': expense.date.toIso8601String(),
        'batch_id': expense.batchId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabaseClient
          .from('expenses')
          .update(data)
          .eq('id', expense.id)
          .select()
          .single();

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      await supabaseClient.from('expenses').delete().eq('id', expenseId);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  @override
  Future<void> createExpenseGroup(String groupTitle, List<String> expenseIds) async {
    try {
      final groupId = DateTime.now().millisecondsSinceEpoch.toString();
      
      await supabaseClient
          .from('expenses')
          .update({
            'group_id': groupId,
            'group_title': groupTitle,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', expenseIds);
    } catch (e) {
      throw Exception('Failed to create expense group: $e');
    }
  }

  @override
  Future<void> updateExpenseGroup({
    required String expenseId,
    String? groupId,
    String? groupTitle,
  }) async {
    try {
      await supabaseClient
          .from('expenses')
          .update({
            'group_id': groupId,
            'group_title': groupTitle,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', expenseId);
    } catch (e) {
      throw Exception('Failed to update expense group: $e');
    }
  }
}
