import 'package:flutter/material.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/sales_usecases.dart';

class SalesProvider with ChangeNotifier {
  final RecordSaleUseCase recordSaleUseCase;
  final GetSalesUseCase getSalesUseCase;
  final GetBatchSalesUseCase getBatchSalesUseCase;
  final UpdatePaymentStatusUseCase updatePaymentStatusUseCase;
  final DeleteSaleUseCase deleteSaleUseCase;
  final CreateSaleGroupUseCase createSaleGroupUseCase;

  SalesProvider({
    required this.recordSaleUseCase,
    required this.getSalesUseCase,
    required this.getBatchSalesUseCase,
    required this.updatePaymentStatusUseCase,
    required this.deleteSaleUseCase,
    required this.createSaleGroupUseCase,
  });

  List<Sale> _sales = [];
  List<Sale> _batchSales = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Sale> get sales => _sales;
  List<Sale> get batchSales => _batchSales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Load all sales for user
  Future<void> loadSales(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sales = await getSalesUseCase(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load sales for specific batch
  Future<void> loadBatchSales(String batchId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _batchSales = await getBatchSalesUseCase(batchId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record a new sale
  Future<Sale?> recordSale({
    required String userId,
    required String batchId,
    required SaleType saleType,
    required int quantity,
    required double pricePerUnit,
    required String currency,
    required DateTime saleDate,
    String? buyerName,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final sale = await recordSaleUseCase(
        userId: userId,
        batchId: batchId,
        saleType: saleType,
        quantity: quantity,
        pricePerUnit: pricePerUnit,
        currency: currency,
        saleDate: saleDate,
        buyerName: buyerName,
        notes: notes,
      );

      _sales.insert(0, sale);
      _batchSales.insert(0, sale);
      _isLoading = false;
      notifyListeners();
      return sale;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update payment status
  Future<bool> updatePaymentStatus(String saleId, PaymentStatus status) async {
    try {
      await updatePaymentStatusUseCase(saleId, status);

      // Update in memory
      final index = _sales.indexWhere((s) => s.id == saleId);
      if (index != -1) {
        _sales[index] = _sales[index].copyWith(paymentStatus: status);
      }

      final batchIndex = _batchSales.indexWhere((s) => s.id == saleId);
      if (batchIndex != -1) {
        _batchSales[batchIndex] =
            _batchSales[batchIndex].copyWith(paymentStatus: status);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a sale
  Future<bool> deleteSale(String saleId) async {
    try {
      await deleteSaleUseCase(saleId);

      _sales.removeWhere((s) => s.id == saleId);
      _batchSales.removeWhere((s) => s.id == saleId);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Calculate batch revenue
  double getBatchRevenue(String batchId) {
    return _sales
        .where((s) => s.batchId == batchId)
        .fold(0, (sum, s) => sum + s.totalAmount);
  }

  /// Calculate batch revenue by type
  Map<SaleType, double> getBatchRevenueByType(String batchId) {
    final Map<SaleType, double> revenues = {};
    for (var saleType in SaleType.values) {
      revenues[saleType] = _sales
          .where((s) => s.batchId == batchId && s.saleType == saleType)
          .fold(0, (sum, s) => sum + s.totalAmount);
    }
    return revenues;
  }

  /// Get total birds sold from batch
  int getBatchBirdsSold(String batchId) {
    return _sales
        .where((s) => s.batchId == batchId && s.saleType == SaleType.birds)
        .fold(0, (sum, s) => sum + s.quantity);
  }

  /// Get pending payments count
  int getPendingPaymentsCount() {
    return _sales.where((s) => s.paymentStatus == PaymentStatus.pending).length;
  }

  /// Get total pending amount
  double getPendingAmount() {
    return _sales
        .where((s) => s.paymentStatus == PaymentStatus.pending)
        .fold(0, (sum, s) => sum + s.totalAmount);
  }

  /// Create a sale group
  Future<bool> createSaleGroup(
      String groupTitle, List<String> saleIds) async {
    try {
      await createSaleGroupUseCase(groupTitle, saleIds);

      // Update local sales with group info
      for (var i = 0; i < _sales.length; i++) {
        if (saleIds.contains(_sales[i].id)) {
          _sales[i] = _sales[i].copyWith(
            groupId: DateTime.now().millisecondsSinceEpoch.toString(),
            groupTitle: groupTitle,
          );
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get sales grouped by group title
  Map<String?, List<Sale>> getSalesGrouped() {
    final Map<String?, List<Sale>> grouped = {};
    
    for (var sale in _sales) {
      final key = sale.groupTitle;
      grouped.putIfAbsent(key, () => []).add(sale);
    }
    
    return grouped;
  }
}
