import 'package:flutter/foundation.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/daily_record.dart';
import '../../domain/usecases/create_batch_usecase.dart';
import '../../domain/usecases/create_daily_record_usecase.dart';
import '../../domain/usecases/delete_batch_usecase.dart';
import '../../domain/usecases/get_batches_usecase.dart';
import '../../domain/usecases/get_daily_records_usecase.dart';
import '../../domain/usecases/get_total_mortality_usecase.dart';
import '../../domain/usecases/start_batch_usecase.dart';

class BatchProvider extends ChangeNotifier {
  final CreateBatchUseCase createBatchUseCase;
  final GetBatchesUseCase getBatchesUseCase;
  final StartBatchUseCase startBatchUseCase;
  final DeleteBatchUseCase deleteBatchUseCase;
  final CreateDailyRecordUseCase createDailyRecordUseCase;
  final GetDailyRecordsUseCase getDailyRecordsUseCase;
  final GetTotalMortalityUseCase getTotalMortalityUseCase;

  BatchProvider({
    required this.createBatchUseCase,
    required this.getBatchesUseCase,
    required this.startBatchUseCase,
    required this.deleteBatchUseCase,
    required this.createDailyRecordUseCase,
    required this.getDailyRecordsUseCase,
    required this.getTotalMortalityUseCase,
  });

  bool _isLoading = false;
  String? _error;
  List<Batch> _batches = [];
  Batch? _currentBatch;
  List<DailyRecord> _dailyRecords = [];
  int _totalMortality = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Batch> get batches => _batches;
  Batch? get currentBatch => _currentBatch;
  List<DailyRecord> get dailyRecords => _dailyRecords;
  int get totalMortality => _totalMortality;

  // Get live birds count for current batch
  int get currentLiveBirds {
    if (_currentBatch?.actualQuantity == null) return 0;
    return _currentBatch!.getCurrentLiveBirds(_totalMortality);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Create a new batch
  Future<bool> createBatch({
    required String name,
    required BirdType birdType,
    String? breed,
    required int expectedQuantity,
    double? purchaseCost,
    String? currency,
    required String userId,
  }) async {
    _setLoading(true);
    _setError(null);

    final result = await createBatchUseCase(
      name: name,
      birdType: birdType,
      breed: breed,
      expectedQuantity: expectedQuantity,
      purchaseCost: purchaseCost,
      currency: currency,
      userId: userId,
    );

    return result.fold(
      (failure) {
        _setError(failure.message);
        _setLoading(false);
        return false;
      },
      (batch) {
        _batches.insert(0, batch);
        _setLoading(false);
        notifyListeners();
        return true;
      },
    );
  }

  // Load all batches for a user
  Future<void> loadBatches(String userId) async {
    _setLoading(true);
    _setError(null);

    final result = await getBatchesUseCase(userId);

    result.fold(
      (failure) {
        _setError(failure.message);
        _setLoading(false);
      },
      (batches) {
        _batches = batches;
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  // Set current batch for detailed view
  void setCurrentBatch(Batch batch) {
    _currentBatch = batch;
    notifyListeners();
  }

  // Start a batch
  Future<bool> startBatch({
    required String batchId,
    required int actualQuantity,
    required DateTime startDate,
  }) async {
    _setLoading(true);
    _setError(null);

    final result = await startBatchUseCase(
      batchId: batchId,
      actualQuantity: actualQuantity,
      startDate: startDate,
    );

    return result.fold(
      (failure) {
        _setError(failure.message);
        _setLoading(false);
        return false;
      },
      (batch) {
        _currentBatch = batch;
        // Update in list
        final index = _batches.indexWhere((b) => b.id == batch.id);
        if (index != -1) {
          _batches[index] = batch;
        }
        _setLoading(false);
        notifyListeners();
        return true;
      },
    );
  }

  // Load daily records for a batch
  Future<void> loadDailyRecords(String batchId) async {
    _setLoading(true);
    _setError(null);

    // Load records
    final recordsResult = await getDailyRecordsUseCase(batchId);
    
    // Load total mortality
    final mortalityResult = await getTotalMortalityUseCase(batchId);

    recordsResult.fold(
      (failure) {
        _setError(failure.message);
        _setLoading(false);
      },
      (records) {
        _dailyRecords = records;
        
        mortalityResult.fold(
          (failure) {
            _totalMortality = 0;
          },
          (total) {
            _totalMortality = total;
          },
        );
        
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  // Create a daily record
  Future<bool> createDailyRecord({
    required String batchId,
    required DateTime date,
    required int mortalityCount,
    String? notes,
  }) async {
    _setLoading(true);
    _setError(null);

    final result = await createDailyRecordUseCase(
      batchId: batchId,
      date: date,
      mortalityCount: mortalityCount,
      notes: notes,
    );

    return result.fold(
      (failure) {
        _setError(failure.message);
        _setLoading(false);
        return false;
      },
      (record) {
        _dailyRecords.insert(0, record);
        _totalMortality += mortalityCount;
        _setLoading(false);
        notifyListeners();
        return true;
      },
    );
  }

  // Clear current batch and records
  void clearCurrentBatch() {
    _currentBatch = null;
    _dailyRecords = [];
    _totalMortality = 0;
    notifyListeners();
  }

  // Delete a batch
  Future<bool> deleteBatch(String batchId) async {
    _setLoading(true);
    _setError(null);

    final result = await deleteBatchUseCase(batchId);

    return result.fold(
      (failure) {
        _setError(failure.message);
        _setLoading(false);
        return false;
      },
      (_) {
        _batches.removeWhere((batch) => batch.id == batchId);
        if (_currentBatch?.id == batchId) {
          clearCurrentBatch();
        }
        _setLoading(false);
        notifyListeners();
        return true;
      },
    );
  }

  // Filter batches by status
  List<Batch> getBatchesByStatus(BatchStatus status) {
    return _batches.where((batch) => batch.status == status).toList();
  }

  // Reduce batch quantity (for sales)
  Future<bool> reduceBatchQuantity(String batchId, int quantitySold) async {
    _setError(null);

    try {
      final batch = _batches.firstWhere((b) => b.id == batchId);
      final currentQuantity = batch.actualQuantity ?? 0;
      final newQuantity = (currentQuantity - quantitySold).clamp(0, currentQuantity);

      final result = await startBatchUseCase(
        batchId: batchId,
        actualQuantity: newQuantity,
        startDate: batch.startDate ?? DateTime.now(),
      );

      return result.fold(
        (failure) {
          _setError(failure.message);
          return false;
        },
        (updatedBatch) {
          final index = _batches.indexWhere((b) => b.id == batchId);
          if (index != -1) {
            _batches[index] = updatedBatch;
          }
          if (_currentBatch?.id == batchId) {
            _currentBatch = updatedBatch;
          }
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _setError('Failed to update batch: $e');
      return false;
    }
  }

}
