import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Clear expense from offline storage and queue deletion
  Future<void> deleteExpenseOffline(String id) async {
    await _expensesStorage.delete(id);
    if (!_isOnline) {
      await _addPendingSync('expense_delete', id, {'id': id});
    }
  }

  /// Clear sale from offline storage and queue deletion
  Future<void> deleteSaleOffline(String id) async {
    await _salesStorage.delete(id);
    if (!_isOnline) {
      await _addPendingSync('sales_delete', id, {'id': id});
    }
  }

  /// Queue payment status update for a sale
  Future<void> saveSalePaymentStatusOffline(String id, String status) async {
    if (!_isOnline) {
      await _addPendingSync('sales_payment_status', id, {
        'payment_status': status,
      });
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

    final client = Supabase.instance.client;
    final pending = await getPendingSync();
    for (final item in pending) {
      try {
        final type = item['type'] as String;
        final id = item['id'] as String;
        final data = Map<String, dynamic>.from(item['data'] as Map);

        switch (type) {
          case 'batch':
            await client.from('batches').upsert(data, onConflict: 'id');
            break;
          case 'batch_delete':
            await client.from('batches').delete().eq('id', id);
            break;
          case 'expense':
            await client.from('expenses').upsert(data, onConflict: 'id');
            break;
          case 'expense_delete':
            await client.from('expenses').delete().eq('id', id);
            break;
          case 'sales':
            await client.from('sales').upsert(data, onConflict: 'id');
            break;
          case 'sales_delete':
            await client.from('sales').delete().eq('id', id);
            break;
          case 'sales_payment_status':
            await client
                .from('sales')
                .update({'payment_status': data['payment_status']})
                .eq('id', id);
            break;
          default:
            break;
        }

        await removePendingSync(type, id);
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
