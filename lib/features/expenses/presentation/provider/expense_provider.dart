import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/create_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_expenses_by_date_range_usecase.dart';
import '../../data/datasources/expense_remote_datasource.dart';

class ExpenseProvider with ChangeNotifier {
  final GetExpensesUseCase getExpensesUseCase;
  final CreateExpenseUseCase createExpenseUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;
  final GetExpensesByDateRangeUseCase getExpensesByDateRangeUseCase;
  final ExpenseRemoteDataSource remoteDataSource;

  ExpenseProvider({
    required this.getExpensesUseCase,
    required this.createExpenseUseCase,
    required this.deleteExpenseUseCase,
    required this.getExpensesByDateRangeUseCase,
    required this.remoteDataSource,
  });

  // State fields
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter state
  String _searchQuery = '';

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedExpenseIds = {};

  // Getters
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Filter getters
  String get searchQuery => _searchQuery;

  // Selection mode getters
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedExpenseIds => _selectedExpenseIds;

  /// Get total expenses amount
  double getTotalExpenses() {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get expenses grouped by category
  Map<ExpenseCategory, double> getExpensesByCategory() {
    final Map<ExpenseCategory, double> categoryTotals = {};
    
    for (var expense in _expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    
    return categoryTotals;
  }

  /// Get average expense amount
  double getAverageExpense() {
    if (_expenses.isEmpty) return 0;
    return getTotalExpenses() / _expenses.length;
  }

  /// Get expenses grouped by date
  Map<DateTime, List<Expense>> getExpensesByDate() {
    final Map<DateTime, List<Expense>> grouped = {};
    
    for (var expense in _expenses) {
      final dateOnly = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      
      if (!grouped.containsKey(dateOnly)) {
        grouped[dateOnly] = [];
      }
      grouped[dateOnly]!.add(expense);
    }
    
    return grouped;
  }

  /// Get top spending categories
  List<MapEntry<ExpenseCategory, double>> getTopCategories({int limit = 5}) {
    final categoryTotals = getExpensesByCategory();
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).toList();
  }

  /// Get expense statistics
  Map<String, dynamic> getStatistics() {
    if (_expenses.isEmpty) {
      return {
        'total': 0.0,
        'average': 0.0,
        'count': 0,
        'maxExpense': 0.0,
        'minExpense': 0.0,
        'median': 0.0,
      };
    }

    final amounts = _expenses.map((e) => e.amount).toList();
    amounts.sort();

    return {
      'total': getTotalExpenses(),
      'average': getAverageExpense(),
      'count': _expenses.length,
      'maxExpense': amounts.last,
      'minExpense': amounts.first,
      'median': amounts.length.isOdd
          ? amounts[amounts.length ~/ 2]
          : (amounts[amounts.length ~/ 2 - 1] + amounts[amounts.length ~/ 2]) / 2,
    };
  }

  // Load all expenses
  Future<void> loadExpenses(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await getExpensesUseCase(userId);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (expenses) {
        _expenses = expenses;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Load expenses by date range
  Future<void> loadExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Get current user ID from Supabase
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _errorMessage = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return;
    }

    final result = await getExpensesByDateRangeUseCase(
      userId,
      startDate,
      endDate,
    );
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (expenses) {
        _expenses = expenses;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Filter methods
  List<Expense> get filteredExpenses {
    if (_searchQuery.isEmpty) return _expenses;
    
    return _expenses.where((expense) {
      final query = _searchQuery.toLowerCase();
      final matchesDescription = expense.description
              ?.toLowerCase()
              .contains(query) ??
          false;
      final matchesCategory =
          expense.category.displayName.toLowerCase().contains(query);

      return matchesDescription || matchesCategory;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  // Create expense
  Future<bool> createExpense(Expense expense) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await createExpenseUseCase(expense);
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (newExpense) {
        _expenses.insert(0, newExpense);
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  // Delete expense
  Future<bool> deleteExpense(String expenseId) async {
    _errorMessage = null;

    final result = await deleteExpenseUseCase(expenseId);
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _expenses.removeWhere((e) => e.id == expenseId);
        notifyListeners();
        return true;
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Selection mode methods
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedExpenseIds.clear();
    }
    notifyListeners();
  }

  void toggleExpenseSelection(String expenseId) {
    if (_selectedExpenseIds.contains(expenseId)) {
      _selectedExpenseIds.remove(expenseId);
    } else {
      _selectedExpenseIds.add(expenseId);
    }
    notifyListeners();
  }

  void enterSelectionMode(String initialExpenseId) {
    _isSelectionMode = true;
    _selectedExpenseIds.clear();
    _selectedExpenseIds.add(initialExpenseId);
    notifyListeners();
  }

  // Group expenses
  Future<bool> createExpenseGroup(String groupTitle, List<String> expenseIds) async {
    try {
      await remoteDataSource.createExpenseGroup(groupTitle, expenseIds);
      
      // Reload expenses to get updated data
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await loadExpenses(userId);
      }
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create group: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addExpenseToGroup({
    required String expenseId,
    required String groupId,
    required String groupTitle,
  }) async {
    try {
      await remoteDataSource.updateExpenseGroup(
        expenseId: expenseId,
        groupId: groupId,
        groupTitle: groupTitle,
      );

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await loadExpenses(userId);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add expense to group: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeExpenseFromGroup(String expenseId) async {
    try {
      await remoteDataSource.updateExpenseGroup(
        expenseId: expenseId,
        groupId: null,
        groupTitle: null,
      );

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await loadExpenses(userId);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove expense from group: $e';
      notifyListeners();
      return false;
    }
  }

  // Get expenses grouped by groupTitle
  Map<String?, List<Expense>> getExpensesGrouped() {
    final Map<String?, List<Expense>> grouped = {};
    for (var expense in filteredExpenses) {
      grouped.putIfAbsent(expense.groupTitle, () => []).add(expense);
    }
    return grouped;
  }
}
