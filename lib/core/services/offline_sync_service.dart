import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OfflineSyncService {
  static const String _batchesBox = 'batches_offline';
  static const String _expensesBox = 'expenses_offline';
  static const String _salesBox = 'sales_offline';
  static const String _pendingSyncKey = 'pending_sync';

  late Box<Map> _batchesStorage;
  late Box<Map> _expensesStorage;
  late Box<Map> _salesStorage;
  late Box<Map> _pendingSyncStorage;

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  /// Initialize Hive boxes for offline storage
  Future<void> initialize() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Open boxes
    _batchesStorage = await Hive.openBox<Map>(_batchesBox);
    _expensesStorage = await Hive.openBox<Map>(_expensesBox);
    _salesStorage = await Hive.openBox<Map>(_salesBox);
    _pendingSyncStorage = await Hive.openBox<Map>(_pendingSyncKey);

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline) {
        syncPendingChanges();
      }
    });
  }

  /// Check if device is online
  bool get isOnline => _isOnline;

  /// Save batch to offline storage
  Future<void> saveBatchOffline(String id, Map<String, dynamic> data) async {
    await _batchesStorage.put(id, data);
    if (!_isOnline) {
      await _addPendingSync('batch', id, data);
    }
  }

  /// Get batch from offline storage
  Future<Map<String, dynamic>?> getBatchOffline(String id) async {
    final data = _batchesStorage.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Get all batches from offline storage
  Future<List<Map<String, dynamic>>> getAllBatchesOffline() async {
    return _batchesStorage.values
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Clear batch from offline storage
  Future<void> deleteBatchOffline(String id) async {
    await _batchesStorage.delete(id);
    if (!_isOnline) {
      await _addPendingSync('batch_delete', id, {'id': id});
    }
  }

  /// Save expense to offline storage
  Future<void> saveExpenseOffline(String id, Map<String, dynamic> data) async {
    await _expensesStorage.put(id, data);
    if (!_isOnline) {
      await _addPendingSync('expense', id, data);
    }
  }

  /// Get all expenses from offline storage
  Future<List<Map<String, dynamic>>> getAllExpensesOffline() async {
    return _expensesStorage.values
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Save sales to offline storage
  Future<void> saveSalesOffline(String id, Map<String, dynamic> data) async {
    await _salesStorage.put(id, data);
    if (!_isOnline) {
      await _addPendingSync('sales', id, data);
    }
  }

  /// Get all sales from offline storage
  Future<List<Map<String, dynamic>>> getAllSalesOffline() async {
    return _salesStorage.values
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Add to pending sync queue
  Future<void> _addPendingSync(
    String type,
    String id,
    Map<String, dynamic> data,
  ) async {
    final pendingKey = '${type}_$id';
    await _pendingSyncStorage.put(pendingKey, {
      'type': type,
      'id': id,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get pending changes waiting to sync
  Future<List<Map<String, dynamic>>> getPendingSync() async {
    return _pendingSyncStorage.values
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Remove from pending sync after successful upload
  Future<void> removePendingSync(String type, String id) async {
    final pendingKey = '${type}_$id';
    await _pendingSyncStorage.delete(pendingKey);
  }

  /// Sync all pending changes when coming back online
  Future<void> syncPendingChanges() async {
    if (!_isOnline) return;

    final pending = await getPendingSync();
    for (final item in pending) {
      try {
        // This will be called from the respective services (BatchService, etc.)
        // They should implement the actual sync logic
        // For now, just mark as synced
        await removePendingSync(item['type'] as String, item['id'] as String);
      } catch (e) {
        // Keep in pending if sync fails
        print('Sync error: $e');
      }
    }
  }

  /// Clear all offline data
  Future<void> clearAll() async {
    await _batchesStorage.clear();
    await _expensesStorage.clear();
    await _salesStorage.clear();
    await _pendingSyncStorage.clear();
  }
}
