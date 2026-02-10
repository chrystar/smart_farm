# Expenses Feature - Complete Learning Guide

## Table of Contents
1. [High-Level Summary](#high-level-summary)
2. [Architecture Overview](#architecture-overview)
3. [File-by-File Deep Dive](#file-by-file-deep-dive)
4. [State Management Explained](#state-management-explained)
5. [Key Concepts & Syntax](#key-concepts--syntax)
6. [SOLID Principles Analysis](#solid-principles-analysis)
7. [Challenge Tasks](#challenge-tasks)

---

## High-Level Summary

### What Does the Expenses Feature Do?

The **Expenses feature** tracks all farm-related spending and provides financial insights. It helps farmers understand where their money goes and make better business decisions.

**Real-world example:**
- You buy 20 bags of feed for $500 → Create expense (category: Feed)
- You hire workers for $200 → Create expense (category: Labor)
- You group multiple feed purchases → Create expense group "January Feed"
- You view dashboard → See total spent, top categories, trends

**Key capabilities:**
- ✅ Record expenses with amount, category, description
- ✅ Link expenses to specific batches (optional)
- ✅ Group related expenses together (e.g., "Farm Setup")
- ✅ Filter/search expenses by description or category
- ✅ View analytics: total spent, average, category breakdown
- ✅ Date range filtering for reports
- ✅ Multi-select and batch operations

### Why This Feature Matters

**Business value:**
- Track farm profitability (Revenue - Expenses)
- Identify cost-saving opportunities
- Budget planning for next season
- Tax preparation and record keeping
- Batch-level cost analysis (cost per bird)

**Example insights:**
- "Feed costs 60% of total expenses"
- "Average daily expense: $45"
- "Batch #123 cost $2,500 total"

---

## Architecture Overview

### The Clean Architecture Pattern (Same as Batch)

```
┌─────────────────────────────────────────┐
│  PRESENTATION (UI)                      │  ← Screens, Provider
│  - expense_provider.dart                │
│  - expenses_screen.dart                 │
│  - expense_dashboard_screen.dart        │
├─────────────────────────────────────────┤
│  DOMAIN (Business Logic)                │  ← Pure Dart, no dependencies
│  - expense.dart (entity)                │
│  - expense_repository.dart (interface)  │
│  - Use cases (create, get, delete)      │
├─────────────────────────────────────────┤
│  DATA (Implementation)                  │  ← Supabase, JSON
│  - expense_model.dart                   │
│  - expense_repository_impl.dart         │
│  - expense_remote_datasource.dart       │
└─────────────────────────────────────────┘
```

### Expenses Feature Folder Structure

```
lib/features/expenses/
├── domain/                      # Business logic
│   ├── entities/
│   │   └── expense.dart        # Core business object
│   ├── repository/
│   │   └── expense_repository.dart  # Contract
│   └── usecases/
│       ├── create_expense_usecase.dart
│       ├── get_expenses_usecase.dart
│       ├── get_expenses_by_date_range_usecase.dart
│       └── delete_expense_usecase.dart
│
├── data/                       # Implementation
│   ├── models/
│   │   └── expense_model.dart      # JSON serialization
│   ├── datasources/
│   │   └── expense_remote_datasource.dart  # Supabase calls
│   └── repository/
│       └── expense_repository_impl.dart
│
└── presentation/               # UI
    ├── provider/
    │   ├── expense_provider.dart   # State management
    │   └── expense_injection.dart  # Dependency injection
    ├── pages/
    │   ├── expenses_screen.dart             # List view
    │   ├── add_expense_screen.dart          # Create form
    │   ├── expense_dashboard_screen.dart    # Analytics
    │   └── expense_group_detail_screen.dart # Group view
    └── services/
        └── expense_report_service.dart      # PDF/CSV export
```

---

## File-by-File Deep Dive

### 1. Domain Layer (Pure Business Logic)

#### `expense.dart` - The Core Entity

**What it is:**
The `Expense` entity represents a single farm expense in pure Dart.

**Full code explanation:**

```dart
import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  // PROPERTIES (Immutable)
  final String id;              // Unique identifier
  final String userId;          // Who created this expense
  final double amount;          // How much spent (e.g., 500.00)
  final String currency;        // Currency code (USD, NGN, etc.)
  final ExpenseCategory category;  // What type of expense
  final String? customCategory; // User-defined category (if category = other)
  final String? description;    // What was bought ("20 bags of feed")
  final DateTime date;          // When expense occurred
  final String? batchId;        // Optional: link to specific batch
  final String? groupId;        // For grouping related expenses
  final String? groupTitle;     // Group name ("January Feed")
  final DateTime createdAt;     // When record was created
  final DateTime updatedAt;     // Last modification

  // Constructor
  const Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.category,
    this.customCategory,        // Optional fields
    this.description,
    required this.date,
    this.batchId,
    this.groupId,
    this.groupTitle,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a copy with changed fields (immutability pattern)
  Expense copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    ExpenseCategory? category,
    String? customCategory,
    String? description,
    DateTime? date,
    String? batchId,
    String? groupId,
    String? groupTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,  // Use new value OR keep current
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      customCategory: customCategory ?? this.customCategory,
      description: description ?? this.description,
      date: date ?? this.date,
      batchId: batchId ?? this.batchId,
      groupId: groupId ?? this.groupId,
      groupTitle: groupTitle ?? this.groupTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // For comparison (from Equatable)
  @override
  List<Object?> get props => [
    id, userId, amount, currency, category,
    customCategory, description, date, batchId,
    groupId, groupTitle, createdAt, updatedAt,
  ];
}

// Enum: Predefined expense categories
enum ExpenseCategory {
  feed,           // Animal feed
  birds,          // Chicks/birds purchase
  medicine,       // Vaccines, treatments
  equipment,      // Cages, feeders, drinkers
  utilities,      // Electricity, water
  labor,          // Worker salaries
  transportation, // Delivery, vehicle costs
  maintenance,    // Repairs
  marketing,      // Advertising, sales costs
  other,          // Miscellaneous
}

// Extension: Add methods to enum
extension ExpenseCategoryExtension on ExpenseCategory {
  // Human-readable name
  String get displayName {
    switch (this) {
      case ExpenseCategory.feed:
        return 'Feed';
      case ExpenseCategory.birds:
        return 'Chicks/Birds';
      case ExpenseCategory.medicine:
        return 'Medicine & Vaccines';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.labor:
        return 'Labor';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  // Icon for UI
  String get icon {
    switch (this) {
      case ExpenseCategory.feed:
        return '🌾';
      case ExpenseCategory.birds:
        return '🐔';
      case ExpenseCategory.medicine:
        return '💊';
      case ExpenseCategory.equipment:
        return '🔧';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.labor:
        return '👷';
      case ExpenseCategory.transportation:
        return '🚚';
      case ExpenseCategory.maintenance:
        return '🔨';
      case ExpenseCategory.marketing:
        return '📢';
      case ExpenseCategory.other:
        return '📦';
    }
  }
}
```

**Key concepts explained:**

1. **Enums for type safety**: Categories are predefined, prevents typos
2. **Extensions**: Add methods to existing types (enum → displayName)
3. **Nullable fields**: `String?` means optional, can be null
4. **Equatable**: Makes object comparison easy (`expense1 == expense2`)
5. **Immutability**: Once created, fields can't change (use `copyWith`)

**Why this design?**
- ✅ **Type-safe categories**: Can't enter invalid category
- ✅ **Flexible grouping**: Group related expenses for analysis
- ✅ **Batch linkage**: Track costs per batch
- ✅ **Multi-currency**: Support different currencies
- ✅ **Pure Dart**: No UI or database dependencies

**Business rules enforced:**
```dart
// Can't have negative amounts (enforced in use case)
// Can't create expense without category
// Date must be valid DateTime
// Amount is double for precision (not int)
```

---

#### `expense_model.dart` - JSON Serialization

**Why separate from entity?**
- Entity = business logic (pure)
- Model = database/JSON handling (implementation detail)

```dart
import '../../domain/entities/expense.dart';

// Model extends entity, adds serialization
class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.userId,
    required super.amount,
    required super.currency,
    required super.category,
    super.customCategory,
    super.description,
    required super.date,
    super.batchId,
    super.groupId,
    super.groupTitle,
    required super.createdAt,
    required super.updatedAt,
  });

  // Convert FROM JSON (Database → Dart object)
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,  // snake_case → camelCase
      
      // Convert number to double (DB might return int or double)
      amount: (json['amount'] as num).toDouble(),
      
      currency: json['currency'] as String,
      
      // Parse enum from string
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == json['category'],  // e.name = 'feed', 'birds', etc.
        orElse: () => ExpenseCategory.other,  // Fallback if invalid
      ),
      
      // Nullable fields
      customCategory: json['custom_category'] as String?,
      description: json['description'] as String?,
      
      // Parse ISO8601 string to DateTime
      date: DateTime.parse(json['date'] as String),
      
      batchId: json['batch_id'] as String?,
      groupId: json['group_id'] as String?,
      groupTitle: json['group_title'] as String?,
      
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert TO JSON (Dart object → Database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,  // camelCase → snake_case
      'amount': amount,
      'currency': currency,
      'category': category.name,  // Enum → string
      'custom_category': customCategory,
      'description': description,
      'date': date.toIso8601String(),  // DateTime → string
      'batch_id': batchId,
      'group_id': groupId,
      'group_title': groupTitle,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert entity to model
  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      userId: expense.userId,
      amount: expense.amount,
      currency: expense.currency,
      category: expense.category,
      customCategory: expense.customCategory,
      description: expense.description,
      date: expense.date,
      batchId: expense.batchId,
      groupId: expense.groupId,
      groupTitle: expense.groupTitle,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
  }
}
```

**Key concepts:**

1. **`as` type casting**: Tell Dart "this is definitely a String"
2. **`firstWhere()` with `orElse`**: Find enum, fallback if not found
3. **`.name` on enum**: Gets string value ('feed', 'birds', etc.)
4. **ISO8601**: Standard date format for APIs
5. **Factory constructors**: Alternative creation patterns

**Why this pattern?**
- ✅ **Separation of concerns**: Entity stays pure
- ✅ **Database independence**: Change JSON structure without changing entity
- ✅ **Type safety**: Parsing errors caught early

---

### 2. Data Layer (Implementation)

#### `expense_remote_datasource.dart` - Supabase Communication

**What it does:**
Makes actual HTTP calls to Supabase database.

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense_model.dart';

// Abstract interface (contract)
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

// Concrete implementation
class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final SupabaseClient supabaseClient;

  ExpenseRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<ExpenseModel>> getExpenses(String userId) async {
    try {
      // SQL: SELECT * FROM expenses WHERE user_id = userId ORDER BY date DESC
      final response = await supabaseClient
          .from('expenses')           // Table name
          .select()                   // SELECT *
          .eq('user_id', userId)      // WHERE user_id = userId
          .order('date', ascending: false);  // ORDER BY date DESC

      // Convert JSON array to List<ExpenseModel>
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
      // SQL: WHERE date >= startDate AND date <= endDate
      final response = await supabaseClient
          .from('expenses')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())  // ≥ greater than or equal
          .lte('date', endDate.toIso8601String())    // ≤ less than or equal
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
      // SQL: WHERE batch_id = batchId
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
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    try {
      final data = {
        'user_id': expense.userId,
        'amount': expense.amount,
        'currency': expense.currency,
        'category': expense.category.name,  // Enum to string
        'custom_category': expense.customCategory,
        'description': expense.description,
        'date': expense.date.toIso8601String(),
        'batch_id': expense.batchId,
      };

      // SQL: INSERT INTO expenses VALUES (...) RETURNING *
      final response = await supabaseClient
          .from('expenses')
          .insert(data)      // Insert data
          .select()          // Return inserted row
          .single();         // Expect exactly one row

      return ExpenseModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      // SQL: DELETE FROM expenses WHERE id = expenseId
      await supabaseClient
          .from('expenses')
          .delete()
          .eq('id', expenseId);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  @override
  Future<void> createExpenseGroup(
    String groupTitle,
    List<String> expenseIds,
  ) async {
    try {
      // Generate unique group ID
      final groupId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // SQL: UPDATE expenses SET group_id = X, group_title = Y
      //      WHERE id IN (expenseIds)
      await supabaseClient
          .from('expenses')
          .update({
            'group_id': groupId,
            'group_title': groupTitle,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', expenseIds);  // WHERE id IN [...]
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
      // Update single expense's group info
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
```

**Key concepts:**

1. **Abstract interface**: Defines contract, allows mocking for tests
2. **Method chaining**: `.from().select().eq().order()`
3. **Query operators**:
   - `.eq()` = equals
   - `.gte()` = greater than or equal
   - `.lte()` = less than or equal
   - `.inFilter()` = WHERE IN (...)
4. **Error handling**: Try/catch with descriptive messages
5. **Async/await**: Non-blocking database calls

**Why abstract interface?**
- ✅ **Testability**: Mock datasource for offline tests
- ✅ **Flexibility**: Swap Supabase for Firebase later
- ✅ **Contract**: Documents what methods must exist

---

### 3. Presentation Layer (UI + State Management)

#### `expense_provider.dart` - State Management with Provider

**What it does:**
Manages expense state and provides methods for UI to interact with data.

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/get_expenses_usecase.dart';
import '../../domain/usecases/create_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/get_expenses_by_date_range_usecase.dart';
import '../../data/datasources/expense_remote_datasource.dart';

// ChangeNotifier = built-in Flutter class for state management
class ExpenseProvider with ChangeNotifier {
  // DEPENDENCIES (injected via constructor)
  final GetExpensesUseCase getExpensesUseCase;
  final CreateExpenseUseCase createExpenseUseCase;
  final DeleteExpenseUseCase deleteExpenseUseCase;
  final GetExpensesByDateRangeUseCase getExpensesByDateRangeUseCase;
  final ExpenseRemoteDataSource remoteDataSource;

  // Constructor injection (Dependency Injection pattern)
  ExpenseProvider({
    required this.getExpensesUseCase,
    required this.createExpenseUseCase,
    required this.deleteExpenseUseCase,
    required this.getExpensesByDateRangeUseCase,
    required this.remoteDataSource,
  });

  // STATE (private fields with public getters)
  List<Expense> _expenses = [];        // All expenses
  bool _isLoading = false;             // Loading indicator
  String? _errorMessage;               // Error message
  String _searchQuery = '';            // Search filter
  bool _isSelectionMode = false;       // Multi-select mode
  final Set<String> _selectedExpenseIds = {};  // Selected items

  // PUBLIC GETTERS (read-only access to state)
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedExpenseIds => _selectedExpenseIds;

  // COMPUTED PROPERTIES (derived from state)

  /// Get total amount spent
  double getTotalExpenses() {
    // Fold = reduce list to single value
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get expenses grouped by category
  Map<ExpenseCategory, double> getExpensesByCategory() {
    final Map<ExpenseCategory, double> categoryTotals = {};
    
    for (var expense in _expenses) {
      // Add expense amount to category total
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
      // Normalize to date-only (ignore time)
      final dateOnly = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      
      // Add to group
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
    
    // Convert to list and sort by amount (descending)
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top N
    return sorted.take(limit).toList();
  }

  /// Get detailed statistics
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

    // Extract and sort amounts
    final amounts = _expenses.map((e) => e.amount).toList();
    amounts.sort();

    return {
      'total': getTotalExpenses(),
      'average': getAverageExpense(),
      'count': _expenses.length,
      'maxExpense': amounts.last,
      'minExpense': amounts.first,
      // Median = middle value (or average of two middle values)
      'median': amounts.length.isOdd
          ? amounts[amounts.length ~/ 2]  // ~/ = integer division
          : (amounts[amounts.length ~/ 2 - 1] + amounts[amounts.length ~/ 2]) / 2,
    };
  }

  // ACTIONS (methods that change state)

  /// Load all expenses for user
  Future<void> loadExpenses(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();  // Tell UI "I'm loading"

    final result = await getExpensesUseCase(userId);
    
    // Use case returns Either<Failure, List<Expense>>
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();  // Tell UI "Error occurred"
      },
      (expenses) {
        _expenses = expenses;
        _isLoading = false;
        notifyListeners();  // Tell UI "Data loaded"
      },
    );
  }

  /// Load expenses by date range
  Future<void> loadExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Get current user ID
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

  /// Get filtered expenses (by search query)
  List<Expense> get filteredExpenses {
    if (_searchQuery.isEmpty) return _expenses;
    
    return _expenses.where((expense) {
      final query = _searchQuery.toLowerCase();
      
      // Check if description contains query
      final matchesDescription = expense.description
              ?.toLowerCase()
              .contains(query) ??
          false;
      
      // Check if category contains query
      final matchesCategory =
          expense.category.displayName.toLowerCase().contains(query);

      return matchesDescription || matchesCategory;
    }).toList();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();  // Rebuild filtered list
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Create new expense
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
        return false;  // Failure
      },
      (newExpense) {
        _expenses.insert(0, newExpense);  // Add to top of list
        _isLoading = false;
        notifyListeners();
        return true;  // Success
      },
    );
  }

  /// Delete expense
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
        // Remove from local list
        _expenses.removeWhere((e) => e.id == expenseId);
        notifyListeners();
        return true;
      },
    );
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // SELECTION MODE METHODS

  /// Toggle selection mode on/off
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedExpenseIds.clear();  // Clear selections when exiting
    }
    notifyListeners();
  }

  /// Toggle single expense selection
  void toggleExpenseSelection(String expenseId) {
    if (_selectedExpenseIds.contains(expenseId)) {
      _selectedExpenseIds.remove(expenseId);
    } else {
      _selectedExpenseIds.add(expenseId);
    }
    notifyListeners();
  }

  /// Enter selection mode and select first item
  void enterSelectionMode(String initialExpenseId) {
    _isSelectionMode = true;
    _selectedExpenseIds.clear();
    _selectedExpenseIds.add(initialExpenseId);
    notifyListeners();
  }

  // GROUP MANAGEMENT METHODS

  /// Create expense group from selected expenses
  Future<bool> createExpenseGroup(
    String groupTitle,
    List<String> expenseIds,
  ) async {
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

  /// Add expense to existing group
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

      // Reload to reflect changes
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

  /// Remove expense from group
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

  /// Get expenses grouped by groupTitle
  Map<String?, List<Expense>> getExpensesGrouped() {
    final Map<String?, List<Expense>> grouped = {};
    
    for (var expense in filteredExpenses) {
      // Group by groupTitle (null for ungrouped)
      grouped.putIfAbsent(expense.groupTitle, () => []).add(expense);
    }
    
    return grouped;
  }
}
```

**Key concepts:**

1. **ChangeNotifier**: Built-in Flutter mixin for state management
2. **notifyListeners()**: Triggers rebuild of listening widgets
3. **Private fields (`_`)**: Internal state, can't be modified externally
4. **Public getters**: Read-only access to state
5. **Computed properties**: Derived from state (no additional storage)
6. **Fold pattern**: Handle Either<Failure, Success> results
7. **Set<String>**: Unordered collection, no duplicates (for selections)

**State flow:**
```
User Action → Provider Method → Use Case → Repository → DataSource → Supabase
                    ↓
              notifyListeners()
                    ↓
              UI Rebuilds
```

**Why this pattern?**
- ✅ **Centralized state**: One source of truth
- ✅ **Reactive UI**: Automatically updates when state changes
- ✅ **Testable**: Mock use cases, test provider logic
- ✅ **Separation**: Business logic in use cases, UI logic in provider

---

## State Management Explained (Beginner Level)

### What is State?

**State** = data that changes and affects what the user sees.

**Examples in Expenses:**
- List of expenses (empty → loading → filled)
- Search query ("" → "feed")
- Selection mode (off → on)
- Error message (null → "Network error")

### How Provider Works

**Step 1: Provide state at app root**
```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider(...)),
      ],
      child: MyApp(),
    ),
  );
}
```

**Step 2: Listen to state in widgets**
```dart
class ExpensesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Watch = listen to changes, rebuild when notified
    final provider = context.watch<ExpenseProvider>();
    
    if (provider.isLoading) {
      return CircularProgressIndicator();
    }
    
    return ListView.builder(
      itemCount: provider.filteredExpenses.length,
      itemBuilder: (context, index) {
        final expense = provider.filteredExpenses[index];
        return ListTile(
          title: Text(expense.description ?? 'No description'),
          subtitle: Text(expense.category.displayName),
          trailing: Text('\$${expense.amount}'),
        );
      },
    );
  }
}
```

**Step 3: Trigger state changes**
```dart
// In a button handler
ElevatedButton(
  onPressed: () async {
    final provider = context.read<ExpenseProvider>();  // Read = no listen
    final success = await provider.createExpense(newExpense);
    if (success) {
      Navigator.pop(context);
    }
  },
  child: Text('Save'),
)
```

### Key Methods

- **`context.watch<T>()`**: Listen to provider, rebuild on changes
- **`context.read<T>()`**: Get provider without listening (for actions)
- **`notifyListeners()`**: Tell watchers to rebuild

### Example: Search Flow

```dart
// 1. User types in search box
TextField(
  onChanged: (value) {
    context.read<ExpenseProvider>().setSearchQuery(value);
  },
)

// 2. Provider updates state
void setSearchQuery(String query) {
  _searchQuery = query;
  notifyListeners();  // ← Triggers rebuild
}

// 3. UI rebuilds with filtered data
final provider = context.watch<ExpenseProvider>();
final expenses = provider.filteredExpenses;  // Recomputed
```

---

## Key Concepts & Syntax

### 1. Collections & Functional Programming

**Map operations:**

```dart
// Transform list
List<double> amounts = expenses.map((e) => e.amount).toList();

// Filter list
List<Expense> feedExpenses = expenses.where((e) => 
  e.category == ExpenseCategory.feed
).toList();

// Reduce to single value
double total = expenses.fold(0.0, (sum, e) => sum + e.amount);

// Group by key
Map<ExpenseCategory, List<Expense>> grouped = {};
for (var expense in expenses) {
  grouped.putIfAbsent(expense.category, () => []).add(expense);
}

// Sort
expenses.sort((a, b) => b.date.compareTo(a.date));  // Newest first
```

**Map vs Set:**

```dart
// Map: key-value pairs
Map<String, double> categoryTotals = {
  'feed': 500.0,
  'labor': 200.0,
};

// Set: unique values only
Set<String> selectedIds = {'id1', 'id2'};
selectedIds.add('id1');  // No duplicate, still 2 items
```

### 2. Null Safety Patterns

```dart
// Nullable type
String? description = null;  // Can be null

// Null-aware operator
int length = description?.length ?? 0;  // 0 if null

// Null assertion (dangerous!)
String definite = description!;  // Throws if null

// If-null assignment
description ??= 'Default value';  // Assign only if null

// Safe navigation
final upper = expense.description?.toUpperCase();  // null if description is null
```

### 3. Extension Methods

**Add methods to existing types:**

```dart
// Define extension
extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.feed:
        return 'Feed';
      case ExpenseCategory.birds:
        return 'Chicks/Birds';
      // ...
    }
  }
}

// Use extension
ExpenseCategory category = ExpenseCategory.feed;
print(category.displayName);  // "Feed"
```

### 4. Enum Pattern Matching

```dart
// Exhaustive switch (compiler checks all cases)
String getIcon(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.feed:
      return '🌾';
    case ExpenseCategory.birds:
      return '🐔';
    // ... must handle ALL cases
  }
}

// Find enum by name
ExpenseCategory category = ExpenseCategory.values.firstWhere(
  (e) => e.name == 'feed',
  orElse: () => ExpenseCategory.other,
);
```

### 5. Date/Time Operations

```dart
// Parse from string
DateTime date = DateTime.parse('2024-01-15T10:30:00Z');

// Format to string
String iso = date.toIso8601String();  // "2024-01-15T10:30:00.000Z"

// Normalize to date-only (ignore time)
DateTime dateOnly = DateTime(date.year, date.month, date.day);

// Compare dates
bool isBefore = date1.isBefore(date2);
bool isAfter = date1.isAfter(date2);

// Date arithmetic
DateTime tomorrow = date.add(Duration(days: 1));
DateTime lastWeek = date.subtract(Duration(days: 7));
```

---

## SOLID Principles Analysis

### ✅ Single Responsibility Principle (SRP)

**"Each class should have one reason to change"**

**Good examples:**
- ✅ `Expense` entity: Only represents expense data
- ✅ `ExpenseModel`: Only handles JSON serialization
- ✅ `ExpenseRemoteDataSource`: Only handles Supabase calls
- ✅ Each use case: One specific operation

**Could be improved:**
- 🔴 `ExpenseProvider`: Does too much!
  - Manages expenses state
  - Handles search filtering
  - Manages selection mode
  - Manages grouping
  - Computes statistics

**Better approach:**
```dart
// Split into smaller providers
class ExpenseListProvider { }  // List & CRUD
class ExpenseFilterProvider { }  // Search & filters
class ExpenseSelectionProvider { }  // Selection mode
class ExpenseAnalyticsProvider { }  // Statistics
```

### ✅ Open/Closed Principle (OCP)

**"Open for extension, closed for modification"**

**Good example:**
```dart
// Want to add new category? Just add to enum!
enum ExpenseCategory {
  feed,
  birds,
  medicine,
  // NEW:
  insurance,  // ← Extension, no modification
}

// Extension adds methods without modifying enum
extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName { /* ... */ }
  String get icon { /* ... */ }
}
```

**In this app:**
- ✅ Add new datasource (Firebase) without changing use cases
- ✅ Add new category without changing core logic
- ✅ Add new filters without changing entity

### ✅ Liskov Substitution Principle (LSP)

**"Subtypes must be substitutable for base types"**

**Good example:**
```dart
// ExpenseModel can replace Expense anywhere
Expense expense = ExpenseModel(...);  // ✅ Works

// Datasource implementations are interchangeable
ExpenseRemoteDataSource dataSource = ExpenseRemoteDataSourceImpl(...);
ExpenseRemoteDataSource mockDataSource = MockExpenseDataSource();  // For tests
```

### ✅ Interface Segregation Principle (ISP)

**"Don't force classes to implement unused methods"**

**Good example:**
```dart
// Abstract datasource defines specific contract
abstract class ExpenseRemoteDataSource {
  Future<List<ExpenseModel>> getExpenses(String userId);
  Future<ExpenseModel> createExpense(ExpenseModel expense);
  // ... only methods actually used
}
```

**Could be improved:**
```dart
// Instead of one big interface, split:
abstract class ExpenseReader {
  Future<List<ExpenseModel>> getExpenses(String userId);
  Future<List<ExpenseModel>> getExpensesByDateRange(...);
}

abstract class ExpenseWriter {
  Future<ExpenseModel> createExpense(ExpenseModel expense);
  Future<void> deleteExpense(String expenseId);
}

abstract class ExpenseGroupManager {
  Future<void> createExpenseGroup(...);
  Future<void> updateExpenseGroup(...);
}
```

### ✅ Dependency Inversion Principle (DIP)

**"Depend on abstractions, not concretions"**

**Good example:**
```dart
// Use case depends on abstract repository
class CreateExpenseUseCase {
  final ExpenseRepository repository;  // ← Interface, not implementation
  
  CreateExpenseUseCase(this.repository);  // Injected
}

// Can inject ANY implementation
final useCase1 = CreateExpenseUseCase(ExpenseRepositoryImpl(...));
final useCase2 = CreateExpenseUseCase(MockExpenseRepository());
```

**Why it matters:**
- ✅ Testable: Inject mocks
- ✅ Flexible: Swap implementations
- ✅ Maintainable: Changes don't cascade

### 🔴 Areas for Improvement

1. **God Provider** (violates SRP):
```dart
// Currently: ExpenseProvider does everything
// Better: Split responsibilities

class ExpenseListProvider { }
class ExpenseFilterProvider { }
class ExpenseAnalyticsProvider { }
```

2. **Direct Supabase coupling in provider**:
```dart
// Currently: Provider imports Supabase directly
final userId = Supabase.instance.client.auth.currentUser?.id;

// Better: Inject auth service
abstract class AuthService {
  String? get currentUserId;
}
```

3. **Error handling** (could use custom types):
```dart
// Currently: Generic exceptions
throw Exception('Failed to...');

// Better: Type-safe errors
sealed class ExpenseError {
  const ExpenseError();
}

class NetworkError extends ExpenseError {}
class ValidationError extends ExpenseError {
  final String message;
  const ValidationError(this.message);
}
```

---

## Challenge Tasks

### Challenge 1: Add Tax Field (Easy)

**Objective:** Add optional tax amount to expenses.

**Steps:**
1. Add `double? taxAmount` to `Expense` entity
2. Add to constructor and `copyWith`
3. Add to `ExpenseModel.fromJson()` and `toJson()`
4. Update database migration
5. Add TextField in add expense screen
6. Display tax in expense details

**Success criteria:**
- Can save tax amount
- Tax displays in list/detail
- Stats include tax in totals
- Works with null (optional)

### Challenge 2: Filter by Category (Medium)

**Objective:** Add category filter dropdown.

**Steps:**
1. Add `ExpenseCategory? _categoryFilter` to provider
2. Add `filterByCategory(ExpenseCategory? category)` method
3. Modify `filteredExpenses` to apply category filter
4. Add dropdown in expenses screen
5. Wire dropdown to provider
6. Show "All Categories" option

**Success criteria:**
- Can filter by single category
- "All" shows everything
- Works with search (both filters)
- Filter persists during session

### Challenge 3: Recurring Expenses (Hard)

**Objective:** Support recurring expenses (weekly, monthly).

**Steps:**
1. Add `RecurrenceType?` enum (none, daily, weekly, monthly)
2. Add to entity and model
3. Create `CreateRecurringExpenseUseCase`
4. Add logic to generate future expenses
5. Add UI toggle in add expense screen
6. Add "Upcoming" section in list

**Success criteria:**
- Can create recurring expense
- Generates correct dates
- Shows upcoming expenses
- Can edit/cancel recurrence

### Challenge 4: Export to CSV (Medium-Hard)

**Objective:** Export expenses as CSV file.

**Steps:**
1. Create `ExpenseExportService` in services
2. Add `exportToCsv(List<Expense> expenses)` method
3. Use `csv` package for formatting
4. Use `share_plus` to share file
5. Add export button in app bar
6. Support date range selection

**Success criteria:**
- CSV has all fields
- Proper formatting
- Can share via email/apps
- Works on iOS and Android

### Challenge 5: Expense Analytics Dashboard (Advanced)

**Objective:** Build comprehensive analytics screen.

**Steps:**
1. Create `ExpenseAnalyticsProvider`
2. Add methods:
   - `getTrendByMonth()` (spending trend)
   - `getCategoryPercentages()` (pie chart data)
   - `getMonthOverMonthGrowth()`
3. Create `expense_analytics_screen.dart`
4. Add charts using `fl_chart` package
5. Add date range selector
6. Add insights (e.g., "Feed costs up 20%")

**Success criteria:**
- Interactive charts
- Meaningful insights
- Responsive to date range
- Smooth animations

### Challenge 6: Refactor Provider (Expert)

**Objective:** Split ExpenseProvider following SRP.

**Steps:**
1. Create `ExpenseListProvider` (CRUD only)
2. Create `ExpenseFilterProvider` (search, filters)
3. Create `ExpenseAnalyticsProvider` (stats)
4. Create `ExpenseSelectionProvider` (selection mode)
5. Update UI to use multiple providers
6. Ensure providers communicate via events
7. Add integration tests

**Success criteria:**
- Each provider has one responsibility
- No code duplication
- All features still work
- Improved testability

---

## Additional Resources

### Recommended Reading
- [Provider Documentation](https://pub.dev/packages/provider)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture-tdd/)
- [Equatable Package](https://pub.dev/packages/equatable)

### Practice Projects
1. Add "Budget" feature (set category budgets, track vs actual)
2. Add "Receipt" photos (image upload per expense)
3. Add "Payment method" (cash, card, bank transfer)
4. Add "Expense approval" workflow (for team farms)

### Testing Tips

**Unit test for entity:**
```dart
void main() {
  test('copyWith creates new instance with changed fields', () {
    final expense = Expense(
      id: '1',
      userId: 'user1',
      amount: 100.0,
      currency: 'USD',
      category: ExpenseCategory.feed,
      date: DateTime(2024, 1, 1),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final updated = expense.copyWith(amount: 200.0);
    
    expect(updated.amount, 200.0);
    expect(updated.id, '1');  // Other fields unchanged
  });
}
```

**Provider test with mocks:**
```dart
void main() {
  test('loadExpenses updates state on success', () async {
    final mockUseCase = MockGetExpensesUseCase();
    when(mockUseCase('user1')).thenAnswer((_) async => 
      Right([/* test expenses */])
    );
    
    final provider = ExpenseProvider(
      getExpensesUseCase: mockUseCase,
      // ... other mocks
    );
    
    await provider.loadExpenses('user1');
    
    expect(provider.isLoading, false);
    expect(provider.expenses.length, 2);
    expect(provider.errorMessage, null);
  });
}
```

---

## Summary

### Key Takeaways

1. **Clean Architecture Layers**
   - Domain: Pure business logic (entities, use cases)
   - Data: Implementation details (models, datasources)
   - Presentation: UI and state (providers, screens)

2. **State Management with Provider**
   - ChangeNotifier holds state
   - notifyListeners() triggers rebuilds
   - context.watch() to listen, context.read() for actions

3. **SOLID Principles**
   - SRP: One responsibility per class
   - OCP: Extend, don't modify
   - LSP: Subtypes are substitutable
   - ISP: Small, focused interfaces
   - DIP: Depend on abstractions

4. **Key Patterns**
   - Immutability: Use `copyWith` instead of mutations
   - Computed properties: Derive from state
   - Enums: Type-safe categories
   - Extensions: Add methods without modifying types

### Differences from Batch Feature

1. **Grouping**: Expenses support grouping (batches don't)
2. **Multi-select**: Expenses have selection mode
3. **Analytics**: More statistical methods in provider
4. **Filtering**: Search and category filters
5. **Categories**: Enum-based categories vs batch types

### Next Steps

1. Complete Challenge 1 (easiest)
2. Study Provider pattern in depth
3. Implement custom error types
4. Refactor provider (Challenge 6)
5. Build similar feature from scratch

**Remember:** The best way to learn is by breaking things, fixing them, and understanding WHY each piece exists. Start small, iterate, and refactor.

Good luck! 🚀
