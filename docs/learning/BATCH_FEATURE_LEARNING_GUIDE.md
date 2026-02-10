# Batch Feature - Complete Learning Guide

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

### What Does the Batch Feature Do?

The **Batch feature** manages the complete lifecycle of a poultry batch (a group of birds raised together). Think of it like managing a "production cycle" from start to finish.

**Real-world example:**
- You buy 500 broiler chicks on Jan 1st (create batch)
- You activate the batch when they arrive (start tracking)
- Every day you record: deaths, feed consumed, weights (daily records)
- After 42 days, you harvest/sell them (complete batch)

**Key capabilities:**
- ✅ Create and plan batches before birds arrive
- ✅ Activate batches when birds arrive (starts day counting)
- ✅ Record daily mortality, feed, notes
- ✅ Track live bird count automatically
- ✅ View batch performance and history
- ✅ Complete or delete batches

---

## Architecture Overview

### The Clean Architecture Pattern

This app follows **Clean Architecture** (Uncle Bob's pattern), which separates code into layers:

```
┌─────────────────────────────────────────┐
│  PRESENTATION (UI)                      │  ← What users see
│  - Screens, Widgets, Provider           │
├─────────────────────────────────────────┤
│  DOMAIN (Business Logic)                │  ← Pure business rules
│  - Entities, Use Cases, Repository Abs  │
├─────────────────────────────────────────┤
│  DATA (External World)                  │  ← Database, APIs
│  - Models, Repository Impl, DataSource  │
└─────────────────────────────────────────┘
```

**Why this matters:**
- **Testability**: You can test business logic without a database
- **Flexibility**: Swap Supabase for Firebase without changing business logic
- **Maintainability**: Each layer has one responsibility
- **Team collaboration**: Frontend/backend devs can work independently

### Batch Feature Folder Structure

```
lib/features/batch/
├── domain/                      # Pure business logic (no Flutter, no DB)
│   ├── entities/
│   │   ├── batch.dart          # Core business object
│   │   └── daily_record.dart   # Daily tracking data
│   ├── repository/
│   │   └── batch_repository.dart     # Contract (interface)
│   └── usecases/               # Business operations
│       ├── create_batch_usecase.dart
│       ├── start_batch_usecase.dart
│       ├── create_daily_record_usecase.dart
│       ├── get_batches_usecase.dart
│       ├── get_daily_records_usecase.dart
│       ├── get_total_mortality_usecase.dart
│       └── delete_batch_usecase.dart
│
├── data/                       # Implementation details
│   ├── models/
│   │   ├── batch_model.dart           # JSON serialization
│   │   └── daily_record_model.dart
│   ├── repository/
│   │   └── batch_repository_impl.dart # Actual implementation
│   └── datasources/
│       └── batch_remote_datasource.dart # Supabase calls
│
└── presentation/               # UI layer
    ├── provider/
    │   ├── batch_provider.dart        # State management
    │   └── batch_injection.dart       # Dependency setup
    └── screens/
        ├── batch_list_screen.dart
        ├── batch_detail_screen.dart
        └── create_batch_screen.dart
```

---

## File-by-File Deep Dive

### 1. Domain Layer (Pure Business Logic)

#### `batch.dart` - The Core Entity

**What it is:**
The `Batch` entity represents a poultry batch in your business. It's a pure Dart class with NO dependencies on Flutter or databases.

**Full code explanation:**

```dart
import 'package:equatable/equatable.dart';

// Enums define allowed values (prevents typos/invalid states)
enum BirdType { broiler, layer }  // Only 2 types allowed
enum BatchStatus { planned, active, completed }  // Lifecycle states

class Batch extends Equatable {  // Equatable for easy comparisons
  // PROPERTIES (Immutable - can't be changed after creation)
  final String id;              // Unique identifier
  final String name;            // User-friendly name ("Batch Jan 2024")
  final BirdType birdType;      // Broiler or Layer
  final String? breed;          // Optional: specific breed
  final int expectedQuantity;   // Planned number of birds
  final int? actualQuantity;    // Actual received (null until activated)
  final BatchStatus status;     // Current lifecycle state
  final DateTime? startDate;    // When activated (null if planned)
  final DateTime? endDate;      // When completed (null if active)
  final double? purchaseCost;   // Total cost to buy birds
  final String? currency;       // Currency code (USD, NGN, etc.)
  final String userId;          // Who owns this batch
  final DateTime createdAt;     // When batch record was created
  final DateTime updatedAt;     // Last modification time

  // Constructor (how you create a Batch)
  const Batch({
    required this.id,           // 'required' = MUST provide
    required this.name,
    required this.birdType,
    this.breed,                 // No 'required' = optional
    required this.expectedQuantity,
    this.actualQuantity,
    required this.status,
    this.startDate,
    this.endDate,
    this.purchaseCost,
    this.currency,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  // BUSINESS LOGIC METHODS

  // Calculate live birds (quantity - total deaths)
  int getCurrentLiveBirds(int totalMortality) {
    if (actualQuantity == null) return 0;  // Not started yet
    return actualQuantity! - totalMortality;  // ! = force unwrap (safe here)
  }

  // Calculate which day of the batch cycle we're on
  int? getDaysSinceStart() {
    if (startDate == null) return null;  // Not started
    
    // Normalize to midnight (ignore time of day)
    final start = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
    );
    
    final anchorRaw = endDate ?? DateTime.now();  // Use endDate if completed
    final anchor = DateTime(
      anchorRaw.year,
      anchorRaw.month,
      anchorRaw.day,
    );
    
    if (anchor.isBefore(start)) return 0;  // Safety check
    return anchor.difference(start).inDays + 1;  // +1 for inclusive counting
  }

  // Create a copy with some fields changed (immutability pattern)
  Batch copyWith({
    String? id,
    String? name,
    BirdType? birdType,
    String? breed,
    int? expectedQuantity,
    int? actualQuantity,
    BatchStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? purchaseCost,
    String? currency,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Batch(
      id: id ?? this.id,  // Use new value OR keep current
      name: name ?? this.name,
      birdType: birdType ?? this.birdType,
      breed: breed ?? this.breed,
      expectedQuantity: expectedQuantity ?? this.expectedQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      currency: currency ?? this.currency,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // For comparison and collections (from Equatable)
  @override
  List<Object?> get props => [
    id, name, birdType, breed, expectedQuantity,
    actualQuantity, status, startDate, endDate,
    purchaseCost, userId, createdAt, updatedAt,
  ];
}
```

**Key concepts explained:**

1. **`const` constructor**: Creates compile-time constants (memory efficient)
2. **`final` fields**: Immutable - can't be modified after creation
3. **`?` nullable types**: Can be null (e.g., `String?`, `DateTime?`)
4. **`!` null assertion**: "I guarantee this isn't null" (use carefully!)
5. **`??` null coalescing**: "If left is null, use right" (`a ?? b`)
6. **Equatable**: Makes `batch1 == batch2` work by comparing props

**Why this design?**
- ✅ **Immutable**: No accidental changes, safer in async code
- ✅ **Pure**: No dependencies on UI or database
- ✅ **Testable**: Easy to test `getDaysSinceStart()` logic
- ✅ **Type-safe**: Enums prevent invalid states

---

#### `daily_record.dart` - Daily Tracking Entity

```dart
import 'package:equatable/equatable.dart';

class DailyRecord extends Equatable {
  final String id;              // Unique ID
  final String batchId;         // Which batch this belongs to
  final int dayNumber;          // Day 1, 2, 3... of the batch
  final DateTime recordDate;    // Actual calendar date
  final int deaths;             // How many died today
  final double? feedConsumed;   // Kg of feed (optional)
  final double? avgWeight;      // Average bird weight (optional)
  final String? notes;          // Farmer's notes
  final String userId;          // Who created this record
  final DateTime createdAt;

  const DailyRecord({
    required this.id,
    required this.batchId,
    required this.dayNumber,
    required this.recordDate,
    required this.deaths,
    this.feedConsumed,
    this.avgWeight,
    this.notes,
    required this.userId,
    required this.createdAt,
  });

  // Calculate mortality rate for this day
  double getMortalityRate(int totalBirds) {
    if (totalBirds == 0) return 0.0;
    return (deaths / totalBirds) * 100;  // Returns percentage
  }

  DailyRecord copyWith({
    String? id,
    String? batchId,
    int? dayNumber,
    DateTime? recordDate,
    int? deaths,
    double? feedConsumed,
    double? avgWeight,
    String? notes,
    String? userId,
    DateTime? createdAt,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      dayNumber: dayNumber ?? this.dayNumber,
      recordDate: recordDate ?? this.recordDate,
      deaths: deaths ?? this.deaths,
      feedConsumed: feedConsumed ?? this.feedConsumed,
      avgWeight: avgWeight ?? this.avgWeight,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id, batchId, dayNumber, recordDate, deaths,
    feedConsumed, avgWeight, notes, userId, createdAt,
  ];
}
```

**Why separate from Batch?**
- One batch has MANY daily records (1-to-many relationship)
- Keeps Batch entity simple and focused
- Easier to query/filter daily data independently

---

#### `batch_repository.dart` - The Contract

```dart
import '../entities/batch.dart';
import '../entities/daily_record.dart';

// Abstract class = interface/contract (can't instantiate directly)
abstract class BatchRepository {
  // Returns Future because database operations are async
  Future<List<Batch>> getBatches(String userId);
  
  Future<Batch> createBatch(Batch batch);
  
  Future<void> startBatch(String batchId, int actualQuantity);
  
  Future<void> deleteBatch(String batchId);
  
  Future<List<DailyRecord>> getDailyRecords(String batchId);
  
  Future<DailyRecord> createDailyRecord(DailyRecord record);
  
  Future<int> getTotalMortality(String batchId);
}
```

**Key concepts:**

1. **Abstract class**: Defines WHAT methods exist, not HOW they work
2. **Future<T>**: Async operation that will eventually return type T
3. **Repository Pattern**: Hides data source (could be Supabase, Firebase, local DB)

**Why use this?**
- ✅ **Testability**: Mock repository for tests (no real database)
- ✅ **Flexibility**: Swap implementations without changing business logic
- ✅ **SOLID**: Dependency Inversion Principle (depend on abstraction)

---

#### Use Cases - Business Operations

Each use case does ONE specific business operation. Let's examine one:

**`create_batch_usecase.dart`**

```dart
import '../entities/batch.dart';
import '../repository/batch_repository.dart';

// Use case = single business operation
class CreateBatchUseCase {
  final BatchRepository repository;  // Depends on abstraction, not concrete

  CreateBatchUseCase(this.repository);  // Constructor injection

  // The 'call' method makes this class callable like a function
  Future<Batch> call(Batch batch) async {
    // Business rule: Validate before saving
    if (batch.expectedQuantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }
    
    // Delegate to repository
    return await repository.createBatch(batch);
  }
}
```

**Why separate use cases?**
- ✅ **Single Responsibility**: Each class does ONE thing
- ✅ **Reusability**: Can call from UI, tests, background jobs
- ✅ **Validation**: Business rules in one place
- ✅ **Testability**: Mock repository, test validation logic

**Pattern explanation:**
```dart
// Without use case
final batch = await repository.createBatch(batch);  // No validation!

// With use case
final createBatch = CreateBatchUseCase(repository);
final batch = await createBatch(newBatch);  // Validated automatically
```

---

### 2. Data Layer (Implementation Details)

#### `batch_model.dart` - JSON Serialization

**Why do we need this?**
- Entities are pure business objects
- Models handle database/JSON conversion
- Separation of concerns (entity logic ≠ serialization logic)

```dart
import '../../domain/entities/batch.dart';

// Extends entity, adds serialization methods
class BatchModel extends Batch {
  // Same constructor as Batch
  const BatchModel({
    required super.id,
    required super.name,
    required super.birdType,
    super.breed,
    required super.expectedQuantity,
    super.actualQuantity,
    required super.status,
    super.startDate,
    super.endDate,
    super.purchaseCost,
    super.currency,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
  });

  // Convert FROM JSON (Supabase → Dart object)
  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as String,
      name: json['name'] as String,
      
      // Parse enum from string
      birdType: json['bird_type'] == 'broiler' 
          ? BirdType.broiler 
          : BirdType.layer,
      
      breed: json['breed'] as String?,  // Nullable
      
      expectedQuantity: json['expected_quantity'] as int,
      actualQuantity: json['actual_quantity'] as int?,
      
      // Parse status enum
      status: _parseStatus(json['status'] as String),
      
      // Parse DateTime from ISO string (or null)
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date'] as String) 
          : null,
      
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      
      // Parse double (database might return int or double)
      purchaseCost: json['purchase_cost'] != null
          ? (json['purchase_cost'] as num).toDouble()
          : null,
      
      currency: json['currency'] as String?,
      userId: json['user_id'] as String,
      
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convert TO JSON (Dart object → Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bird_type': birdType == BirdType.broiler ? 'broiler' : 'layer',
      'breed': breed,
      'expected_quantity': expectedQuantity,
      'actual_quantity': actualQuantity,
      'status': _statusToString(status),
      'start_date': startDate?.toIso8601String(),  // null-safe conversion
      'end_date': endDate?.toIso8601String(),
      'purchase_cost': purchaseCost,
      'currency': currency,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper: Parse status string to enum
  static BatchStatus _parseStatus(String status) {
    switch (status) {
      case 'planned':
        return BatchStatus.planned;
      case 'active':
        return BatchStatus.active;
      case 'completed':
        return BatchStatus.completed;
      default:
        return BatchStatus.planned;  // Fallback
    }
  }

  // Helper: Convert status enum to string
  static String _statusToString(BatchStatus status) {
    switch (status) {
      case BatchStatus.planned:
        return 'planned';
      case BatchStatus.active:
        return 'active';
      case BatchStatus.completed:
        return 'completed';
    }
  }

  // Convert entity to model
  factory BatchModel.fromEntity(Batch batch) {
    return BatchModel(
      id: batch.id,
      name: batch.name,
      birdType: batch.birdType,
      breed: batch.breed,
      expectedQuantity: batch.expectedQuantity,
      actualQuantity: batch.actualQuantity,
      status: batch.status,
      startDate: batch.startDate,
      endDate: batch.endDate,
      purchaseCost: batch.purchaseCost,
      currency: batch.currency,
      userId: batch.userId,
      createdAt: batch.createdAt,
      updatedAt: batch.updatedAt,
    );
  }
}
```

**Key concepts:**

1. **`as` casting**: Tell Dart "this is definitely a String"
2. **`?.` null-safe operator**: Only call method if not null
3. **Factory constructor**: Alternative way to create objects
4. **Type conversion**: `num` → `double`, `String` → `DateTime`

**Why this pattern?**
- ✅ **Entity stays pure**: No JSON logic in business layer
- ✅ **Easy to test**: Test entity logic without JSON
- ✅ **Flexible**: Change JSON structure without touching entity

---

#### `batch_remote_datasource.dart` - Supabase Communication

**What it does:**
Makes actual HTTP calls to Supabase database.

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/batch_model.dart';
import '../models/daily_record_model.dart';

class BatchRemoteDataSource {
  final SupabaseClient _client;  // Supabase connection

  BatchRemoteDataSource(this._client);  // Inject dependency

  // Fetch all batches for a user
  Future<List<BatchModel>> getBatches(String userId) async {
    try {
      // SQL: SELECT * FROM batches WHERE user_id = userId ORDER BY created_at DESC
      final response = await _client
          .from('batches')           // Table name
          .select()                  // SELECT *
          .eq('user_id', userId)     // WHERE user_id = userId
          .order('created_at', ascending: false);  // ORDER BY created_at DESC

      // Convert JSON array to List<BatchModel>
      return (response as List)
          .map((json) => BatchModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch batches: $e');
    }
  }

  // Create a new batch
  Future<BatchModel> createBatch(Map<String, dynamic> batchData) async {
    try {
      // SQL: INSERT INTO batches VALUES (...) RETURNING *
      final response = await _client
          .from('batches')
          .insert(batchData)
          .select()          // Return inserted row
          .single();         // Expect exactly one row

      return BatchModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create batch: $e');
    }
  }

  // Activate a batch (set actualQuantity and startDate)
  Future<void> startBatch(String batchId, int actualQuantity) async {
    try {
      // SQL: UPDATE batches SET actual_quantity = X, start_date = NOW(), 
      //      status = 'active', updated_at = NOW() WHERE id = batchId
      await _client.from('batches').update({
        'actual_quantity': actualQuantity,
        'start_date': DateTime.now().toIso8601String(),
        'status': 'active',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', batchId);
    } catch (e) {
      throw Exception('Failed to start batch: $e');
    }
  }

  // Delete a batch
  Future<void> deleteBatch(String batchId) async {
    try {
      // SQL: DELETE FROM batches WHERE id = batchId
      await _client.from('batches').delete().eq('id', batchId);
    } catch (e) {
      throw Exception('Failed to delete batch: $e');
    }
  }

  // Get daily records for a batch
  Future<List<DailyRecordModel>> getDailyRecords(String batchId) async {
    try {
      final response = await _client
          .from('daily_records')
          .select()
          .eq('batch_id', batchId)
          .order('day_number', ascending: true);

      return (response as List)
          .map((json) => DailyRecordModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch daily records: $e');
    }
  }

  // Create a daily record
  Future<DailyRecordModel> createDailyRecord(
      Map<String, dynamic> recordData) async {
    try {
      final response = await _client
          .from('daily_records')
          .insert(recordData)
          .select()
          .single();

      return DailyRecordModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create daily record: $e');
    }
  }

  // Calculate total deaths for a batch
  Future<int> getTotalMortality(String batchId) async {
    try {
      final response = await _client
          .from('daily_records')
          .select('deaths')
          .eq('batch_id', batchId);

      if (response.isEmpty) return 0;

      // Sum all deaths
      return (response as List)
          .fold<int>(0, (sum, record) => sum + (record['deaths'] as int));
    } catch (e) {
      throw Exception('Failed to get total mortality: $e');
    }
  }
}
```

**Key concepts:**

1. **`async`/`await`**: Handle asynchronous operations (network calls)
2. **`try`/`catch`**: Error handling
3. **Method chaining**: `.from().select().eq().order()`
4. **`.fold()`**: Reduce list to single value (like reduce in JS)

**Why separate datasource?**
- ✅ **Testability**: Mock datasource for offline tests
- ✅ **Flexibility**: Swap Supabase for Firebase easily
- ✅ **Single Responsibility**: Only handles HTTP calls

---

#### `batch_repository_impl.dart` - Repository Implementation

**Glues use cases to datasource:**

```dart
import '../../domain/entities/batch.dart';
import '../../domain/entities/daily_record.dart';
import '../../domain/repository/batch_repository.dart';
import '../datasources/batch_remote_datasource.dart';
import '../models/batch_model.dart';
import '../models/daily_record_model.dart';

// Implements the contract from domain layer
class BatchRepositoryImpl implements BatchRepository {
  final BatchRemoteDataSource remoteDataSource;

  BatchRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Batch>> getBatches(String userId) async {
    // Call datasource, return as entities (not models)
    final models = await remoteDataSource.getBatches(userId);
    return models;  // Models extend entities, so this works
  }

  @override
  Future<Batch> createBatch(Batch batch) async {
    // Convert entity to model, then to JSON
    final model = BatchModel.fromEntity(batch);
    final created = await remoteDataSource.createBatch(model.toJson());
    return created;  // Return as entity
  }

  @override
  Future<void> startBatch(String batchId, int actualQuantity) async {
    await remoteDataSource.startBatch(batchId, actualQuantity);
  }

  @override
  Future<void> deleteBatch(String batchId) async {
    await remoteDataSource.deleteBatch(batchId);
  }

  @override
  Future<List<DailyRecord>> getDailyRecords(String batchId) async {
    final models = await remoteDataSource.getDailyRecords(batchId);
    return models;
  }

  @override
  Future<DailyRecord> createDailyRecord(DailyRecord record) async {
    final model = DailyRecordModel.fromEntity(record);
    final created = await remoteDataSource.createDailyRecord(model.toJson());
    return created;
  }

  @override
  Future<int> getTotalMortality(String batchId) async {
    return await remoteDataSource.getTotalMortality(batchId);
  }
}
```

**Why this layer?**
- ✅ **Adapter Pattern**: Converts between domain and data layers
- ✅ **Domain independence**: Use cases don't know about Supabase
- ✅ **Testability**: Mock datasource, test repository logic

---

### 3. Presentation Layer (UI + State Management)

#### `batch_provider.dart` - State Management with Provider

**What is Provider?**
Provider is Flutter's recommended state management solution. Think of it as a "smart bucket" that:
1. Holds state (data)
2. Notifies UI when state changes
3. Rebuilds only affected widgets

```dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/daily_record.dart';
import '../../domain/usecases/create_batch_usecase.dart';
import '../../domain/usecases/get_batches_usecase.dart';
import '../../domain/usecases/start_batch_usecase.dart';
import '../../domain/usecases/delete_batch_usecase.dart';
import '../../domain/usecases/create_daily_record_usecase.dart';
import '../../domain/usecases/get_daily_records_usecase.dart';
import '../../domain/usecases/get_total_mortality_usecase.dart';

// ChangeNotifier = built-in class that notifies listeners when data changes
class BatchProvider with ChangeNotifier {
  // Dependencies (injected)
  final GetBatchesUseCase getBatchesUseCase;
  final CreateBatchUseCase createBatchUseCase;
  final StartBatchUseCase startBatchUseCase;
  final DeleteBatchUseCase deleteBatchUseCase;
  final CreateDailyRecordUseCase createDailyRecordUseCase;
  final GetDailyRecordsUseCase getDailyRecordsUseCase;
  final GetTotalMortalityUseCase getTotalMortalityUseCase;

  // Constructor injection (Dependency Injection pattern)
  BatchProvider({
    required this.getBatchesUseCase,
    required this.createBatchUseCase,
    required this.startBatchUseCase,
    required this.deleteBatchUseCase,
    required this.createDailyRecordUseCase,
    required this.getDailyRecordsUseCase,
    required this.getTotalMortalityUseCase,
  });

  // STATE (private fields with public getters)
  List<Batch> _batches = [];
  List<DailyRecord> _dailyRecords = [];
  int _totalMortality = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Public getters (read-only access)
  List<Batch> get batches => _batches;
  List<DailyRecord> get dailyRecords => _dailyRecords;
  int get totalMortality => _totalMortality;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ACTIONS (methods that change state)

  // Load all batches
  Future<void> loadBatches(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();  // Tell UI "I'm loading, show spinner"

    try {
      _batches = await getBatchesUseCase(userId);
      _isLoading = false;
      notifyListeners();  // Tell UI "Done loading, show data"
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();  // Tell UI "Error occurred, show message"
    }
  }

  // Create new batch
  Future<bool> createBatch(Batch batch) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await createBatchUseCase(batch);
      _batches.insert(0, created);  // Add to top of list
      _isLoading = false;
      notifyListeners();
      return true;  // Success
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;  // Failure
    }
  }

  // Start/activate a batch
  Future<bool> startBatch(String batchId, int actualQuantity) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await startBatchUseCase(batchId, actualQuantity);
      
      // Update local state (optimistic update)
      final index = _batches.indexWhere((b) => b.id == batchId);
      if (index != -1) {
        _batches[index] = _batches[index].copyWith(
          actualQuantity: actualQuantity,
          status: BatchStatus.active,
          startDate: DateTime.now(),
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete batch
  Future<bool> deleteBatch(String batchId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await deleteBatchUseCase(batchId);
      _batches.removeWhere((b) => b.id == batchId);  // Remove from list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load daily records for a batch
  Future<void> loadDailyRecords(String batchId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dailyRecords = await getDailyRecordsUseCase(batchId);
      _totalMortality = await getTotalMortalityUseCase(batchId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create daily record
  Future<bool> createDailyRecord(DailyRecord record) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await createDailyRecordUseCase(record);
      _dailyRecords.add(created);
      _totalMortality += record.deaths;  // Update total
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
```

**Key concepts:**

1. **`with ChangeNotifier`**: Mixin that adds notification capability
2. **`notifyListeners()`**: Triggers rebuild of listening widgets
3. **Private fields (`_`)**: Convention for internal state
4. **Public getters**: Read-only access to state
5. **Optimistic updates**: Update UI immediately, sync with server later

**State flow:**
```
User Action → Provider Method → Use Case → Repository → DataSource → Supabase
                    ↓
              notifyListeners()
                    ↓
              UI Rebuilds
```

---

#### `batch_injection.dart` - Dependency Injection

**What is Dependency Injection?**
Creating objects and wiring dependencies in one place.

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/usecases/create_batch_usecase.dart';
import '../../domain/usecases/get_batches_usecase.dart';
import '../../domain/usecases/start_batch_usecase.dart';
import '../../domain/usecases/delete_batch_usecase.dart';
import '../../domain/usecases/create_daily_record_usecase.dart';
import '../../domain/usecases/get_daily_records_usecase.dart';
import '../../domain/usecases/get_total_mortality_usecase.dart';
import '../../data/datasources/batch_remote_datasource.dart';
import '../../data/repository/batch_repository_impl.dart';
import '../provider/batch_provider.dart';

class BatchInjection {
  static List<SingleChildWidget> get providers {
    return [
      // Create and provide BatchProvider
      ChangeNotifierProvider(
        create: (_) {
          // Build dependency tree
          final supabaseClient = SupabaseService().client;
          final dataSource = BatchRemoteDataSource(supabaseClient);
          final repository = BatchRepositoryImpl(dataSource);

          // Create all use cases
          final getBatches = GetBatchesUseCase(repository);
          final createBatch = CreateBatchUseCase(repository);
          final startBatch = StartBatchUseCase(repository);
          final deleteBatch = DeleteBatchUseCase(repository);
          final createDailyRecord = CreateDailyRecordUseCase(repository);
          final getDailyRecords = GetDailyRecordsUseCase(repository);
          final getTotalMortality = GetTotalMortalityUseCase(repository);

          // Inject into provider
          return BatchProvider(
            getBatchesUseCase: getBatches,
            createBatchUseCase: createBatch,
            startBatchUseCase: startBatch,
            deleteBatchUseCase: deleteBatch,
            createDailyRecordUseCase: createDailyRecord,
            getDailyRecordsUseCase: getDailyRecords,
            getTotalMortalityUseCase: getTotalMortality,
          );
        },
      ),
    ];
  }
}
```

**Why this pattern?**
- ✅ **Single place**: All dependencies created here
- ✅ **Testability**: Replace with mocks easily
- ✅ **Maintainability**: Easy to see dependency graph
- ✅ **Flexibility**: Swap implementations without changing code

---

## State Management Explained (Beginner Level)

### What is State?

**State** = data that can change over time and affects what the user sees.

**Examples:**
- List of batches (empty → loading → filled)
- Loading spinner (hidden → visible)
- Error message (null → "Network error")

### Why Provider?

**Without Provider:**
```dart
class MyScreen extends StatefulWidget {
  // Problem: State lives in widget
  // Can't share with other screens
  // Hard to test
}
```

**With Provider:**
```dart
// State lives in Provider (outside widget tree)
// Multiple screens can access
// Easy to test
class BatchProvider with ChangeNotifier {
  List<Batch> _batches = [];
  
  void loadBatches() async {
    _batches = await fetchFromDB();
    notifyListeners();  // Rebuild listening widgets
  }
}
```

### How Provider Works

1. **Provide** state at top of widget tree:
```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BatchProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

2. **Consume** state in widgets:
```dart
class BatchListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Listen to BatchProvider changes
    final provider = context.watch<BatchProvider>();
    
    if (provider.isLoading) {
      return CircularProgressIndicator();
    }
    
    return ListView.builder(
      itemCount: provider.batches.length,
      itemBuilder: (context, index) {
        final batch = provider.batches[index];
        return ListTile(title: Text(batch.name));
      },
    );
  }
}
```

3. **Trigger** state changes:
```dart
// In a button handler
context.read<BatchProvider>().loadBatches(userId);
```

### Key Methods

- **`context.watch<T>()`**: Listen to changes, rebuild when notified
- **`context.read<T>()`**: Get provider without listening (for actions)
- **`notifyListeners()`**: Tell all watchers to rebuild

---

## Key Concepts & Syntax

### 1. Async Programming

**Future**: A value that will be available in the future.

```dart
// Synchronous (blocks)
int add(int a, int b) {
  return a + b;
}

// Asynchronous (doesn't block)
Future<int> fetchNumber() async {
  await Future.delayed(Duration(seconds: 2));  // Simulate network delay
  return 42;
}

// Using async/await
void example() async {
  print('Start');
  final result = await fetchNumber();  // Wait for result
  print('Got: $result');
  print('End');
}
// Output:
// Start
// (2 second pause)
// Got: 42
// End
```

**Why async?**
- Network calls take time
- Don't freeze UI while waiting
- Handle multiple operations concurrently

### 2. Null Safety

**Nullable vs Non-nullable:**

```dart
String name = 'John';      // Never null
String? nickname = null;   // Can be null

print(name.length);        // ✅ Always works
print(nickname.length);    // ❌ Error! Might be null
print(nickname?.length);   // ✅ Returns null if nickname is null
print(nickname ?? 'N/A');  // ✅ Use 'N/A' if nickname is null
```

**Null assertion (`!`):**
```dart
String? maybeNull = getValue();
String definitelyNotNull = maybeNull!;  // "I guarantee this isn't null"
// ⚠️ Throws error if null! Use carefully.
```

### 3. Collections & Functional Programming

**Common operations:**

```dart
List<int> numbers = [1, 2, 3, 4, 5];

// Map: Transform each element
List<int> doubled = numbers.map((n) => n * 2).toList();  // [2, 4, 6, 8, 10]

// Where: Filter elements
List<int> evens = numbers.where((n) => n % 2 == 0).toList();  // [2, 4]

// Fold: Reduce to single value
int sum = numbers.fold(0, (total, n) => total + n);  // 15

// First/Last/Single
int first = numbers.first;        // 1
int last = numbers.last;          // 5
int? maybeFirst = numbers.firstWhere((n) => n > 10, orElse: () => null);
```

### 4. Constructors

**Types of constructors:**

```dart
class Person {
  final String name;
  final int age;
  
  // 1. Default constructor
  Person(this.name, this.age);
  
  // 2. Named constructor
  Person.adult(this.name) : age = 18;
  
  // 3. Factory constructor
  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(json['name'], json['age']);
  }
  
  // 4. Const constructor (compile-time constant)
  const Person.constant(this.name, this.age);
}

// Usage
var p1 = Person('John', 25);
var p2 = Person.adult('Jane');
var p3 = Person.fromJson({'name': 'Bob', 'age': 30});
const p4 = Person.constant('Alice', 22);
```

### 5. Error Handling

```dart
Future<void> example() async {
  try {
    final data = await fetchData();
    print(data);
  } catch (e) {
    print('Error: $e');
  } finally {
    print('Cleanup code runs no matter what');
  }
}

// Throwing errors
void validate(int value) {
  if (value < 0) {
    throw Exception('Value must be positive');
  }
}
```

---

## SOLID Principles Analysis

### ✅ Single Responsibility Principle (SRP)

**"Each class should have one reason to change"**

**Good examples:**
- ✅ `Batch` entity: Only represents batch data
- ✅ `CreateBatchUseCase`: Only creates batches
- ✅ `BatchRemoteDataSource`: Only handles Supabase calls
- ✅ `BatchModel`: Only handles JSON conversion

**Why it matters:**
- Easy to understand what each class does
- Changes to UI don't affect business logic
- Changes to database don't affect entities

### ✅ Open/Closed Principle (OCP)

**"Open for extension, closed for modification"**

**Good example:**
```dart
// Want to add Firebase support?
// Don't modify existing code, ADD new implementation

class BatchFirebaseDataSource implements BatchRepository {
  // New implementation, existing code untouched
}
```

**In this app:**
- Use cases work with ANY repository implementation
- Can add new data sources without changing business logic

### ✅ Liskov Substitution Principle (LSP)

**"Subtypes must be substitutable for base types"**

**Good example:**
```dart
// BatchModel can replace Batch anywhere
Batch batch = BatchModel(...);  // ✅ Works because Model extends Entity

// Repository implementations are interchangeable
BatchRepository repo = BatchRepositoryImpl(dataSource);
BatchRepository repo = BatchMockRepository();  // For tests
```

### ✅ Interface Segregation Principle (ISP)

**"Don't force classes to implement unused methods"**

**Good example:**
```dart
// Separate interfaces instead of one giant interface
abstract class BatchRepository {
  Future<List<Batch>> getBatches(String userId);
  Future<Batch> createBatch(Batch batch);
}

abstract class DailyRecordRepository {
  Future<List<DailyRecord>> getDailyRecords(String batchId);
  Future<DailyRecord> createDailyRecord(DailyRecord record);
}
```

**Could be improved:**
Currently one repository handles both. Could split into:
- `BatchRepository`
- `DailyRecordRepository`

### ✅ Dependency Inversion Principle (DIP)

**"Depend on abstractions, not concretions"**

**Good example:**
```dart
// Use case depends on abstract repository, not concrete implementation
class CreateBatchUseCase {
  final BatchRepository repository;  // ← Abstract interface
  
  CreateBatchUseCase(this.repository);  // Injected, not created
  
  Future<Batch> call(Batch batch) {
    return repository.createBatch(batch);
  }
}

// Can inject ANY implementation
final useCase1 = CreateBatchUseCase(BatchRepositoryImpl(...));
final useCase2 = CreateBatchUseCase(BatchMockRepository(...));  // For tests
```

**Why it matters:**
- ✅ Testable: Mock dependencies easily
- ✅ Flexible: Swap implementations without changing code
- ✅ Maintainable: Changes to implementation don't affect use cases

### 🔴 Areas for Improvement

1. **God Provider** (violates SRP):
```dart
// BatchProvider does too much: manages batches AND daily records
// Better: Split into BatchProvider and DailyRecordProvider
```

2. **Error handling** (could be better):
```dart
// Currently: throw Exception('message')
// Better: Custom error types
sealed class BatchError {
  const BatchError();
}

class NetworkError extends BatchError {}
class ValidationError extends BatchError {
  final String message;
  const ValidationError(this.message);
}
```

3. **Repository interface** (could be split):
```dart
// Currently: One repository handles batches AND records
// Better: Separate concerns
```

---

## Challenge Tasks

### Challenge 1: Add Batch Notes (Easy)

**Objective:** Add a notes field to batches.

**Steps:**
1. Add `String? notes` to `Batch` entity
2. Add to constructor and `copyWith`
3. Add to `BatchModel.fromJson()` and `toJson()`
4. Update database migration to add column
5. Add TextField in create/edit screens

**Success criteria:**
- Can save notes when creating batch
- Notes display in batch detail screen
- Notes persist after app restart

### Challenge 2: Filter Batches by Status (Medium)

**Objective:** Add filter dropdown to batch list.

**Steps:**
1. Add `BatchStatus? _statusFilter` to `BatchProvider`
2. Add `filterByStatus(BatchStatus? status)` method
3. Modify `loadBatches()` to apply filter
4. Add dropdown in `BatchListScreen`
5. Wire dropdown to provider method

**Success criteria:**
- Can filter "Active" batches only
- Can filter "Completed" batches
- "All" option shows everything
- Filter state persists during session

### Challenge 3: Batch Completion Use Case (Medium)

**Objective:** Create proper use case for completing batches.

**Steps:**
1. Create `CompleteBatchUseCase` in domain layer
2. Add validation: can't complete if not active
3. Add to repository interface
4. Implement in repository impl
5. Add to datasource
6. Wire to provider
7. Add "Complete Batch" button in UI

**Success criteria:**
- Sets `endDate` to now
- Changes status to `completed`
- Validates batch is active
- Updates UI immediately

### Challenge 4: Daily Record Analytics (Hard)

**Objective:** Calculate mortality rate trend.

**Steps:**
1. Create `AnalyzeRecordsUseCase` that:
   - Takes list of DailyRecords
   - Returns trend: improving/worsening/stable
2. Add business logic:
   - Compare recent 3 days vs previous 3 days
   - Calculate average mortality rate for each period
3. Add to provider
4. Display trend indicator in batch detail
5. Add color coding (green/yellow/red)

**Success criteria:**
- Correctly identifies improving mortality
- Handles edge cases (< 6 days of data)
- Visual indicator updates in real-time
- Unit tests pass

### Challenge 5: Refactor to Clean Architecture (Advanced)

**Objective:** Split BatchProvider into smaller providers.

**Steps:**
1. Create `DailyRecordProvider` for daily record operations
2. Move daily record state/methods from `BatchProvider`
3. Create separate use cases file structure
4. Update dependency injection
5. Update UI to use both providers
6. Ensure no breaking changes

**Success criteria:**
- Both providers work independently
- No code duplication
- All existing features work
- SOLID principles followed
- Tests pass

### Challenge 6: Offline Support (Expert)

**Objective:** Cache batches locally, sync when online.

**Steps:**
1. Add `hive` package for local storage
2. Create `BatchLocalDataSource`
3. Modify repository to check local first
4. Implement sync queue for offline changes
5. Add connectivity listener
6. Handle conflicts (last-write-wins)

**Success criteria:**
- View batches offline
- Create batches offline (queued)
- Auto-sync when online
- Conflict resolution works
- No data loss

---

## Additional Resources

### Recommended Reading
- [Flutter Official Docs](https://flutter.dev/docs)
- [Reso Coder Clean Architecture Tutorial](https://resocoder.com/flutter-clean-architecture-tdd/)
- [SOLID Principles in Dart](https://dart.academy/solid-principles/)

### Practice Projects
1. Add "Breed" feature with CRUD
2. Add "Feed Type" with pricing
3. Add analytics dashboard
4. Export batch reports as PDF

### Testing Tips
```dart
// Example unit test for getDaysSinceStart
void main() {
  test('getDaysSinceStart returns correct day', () {
    final batch = Batch(
      id: '1',
      name: 'Test',
      birdType: BirdType.broiler,
      expectedQuantity: 100,
      status: BatchStatus.active,
      startDate: DateTime(2024, 1, 1),
      userId: 'user1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Mock current date as Jan 3
    final days = batch.getDaysSinceStart();
    
    expect(days, 3);  // Jan 1, 2, 3 = Day 3
  });
}
```

---

## Summary

### Key Takeaways

1. **Clean Architecture = Layers**
   - Domain: Pure business logic
   - Data: Implementation details
   - Presentation: UI and state

2. **SOLID Principles = Better Code**
   - Single Responsibility: One reason to change
   - Open/Closed: Extend, don't modify
   - Liskov Substitution: Subtypes are swappable
   - Interface Segregation: Small, focused interfaces
   - Dependency Inversion: Depend on abstractions

3. **Provider = Simple State Management**
   - ChangeNotifier for state
   - notifyListeners() to rebuild
   - context.watch() to listen

4. **Async/Await = Non-blocking Code**
   - Future for delayed values
   - async marks function as asynchronous
   - await waits for result

### Next Steps

1. Complete Challenge 1 (easiest)
2. Add unit tests for entities
3. Explore other features (expenses, sales)
4. Build your own feature from scratch

**Remember:** The best way to learn is by doing. Start with small changes, break things, fix them, and understand WHY each piece exists.

Good luck! 🚀
