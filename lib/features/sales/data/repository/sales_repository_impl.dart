import '../../domain/entities/sale.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/sales_remote_datasource.dart';

class SalesRepositoryImpl implements SalesRepository {
  final SalesRemoteDataSource remoteDataSource;

  SalesRepositoryImpl(this.remoteDataSource);

  @override
  Future<Sale> recordSale({
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
    final totalAmount = quantity * pricePerUnit;

    final saleData = {
      'user_id': userId,
      'batch_id': batchId,
      'sale_type': saleType.name,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_amount': totalAmount,
      'currency': currency,
      'sale_date': saleDate.toIso8601String(),
      'buyer_name': buyerName,
      'payment_status': PaymentStatus.pending.name,
      'notes': notes,
    };

    return await remoteDataSource.recordSale(saleData);
  }

  @override
  Future<List<Sale>> getSales(String userId) async {
    final models = await remoteDataSource.getSales(userId);
    // Create a fresh List<Sale> to avoid runtime type issues when mutating
    return models.map<Sale>((m) => m as Sale).toList(growable: true);
  }

  @override
  Future<List<Sale>> getBatchSales(String batchId) async {
    final models = await remoteDataSource.getBatchSales(batchId);
    // Create a fresh List<Sale> to avoid runtime type issues when mutating
    return models.map<Sale>((m) => m as Sale).toList(growable: true);
  }

  @override
  Future<void> updatePaymentStatus(
      String saleId, PaymentStatus status) async {
    return await remoteDataSource.updatePaymentStatus(saleId, status.name);
  }

  @override
  Future<void> deleteSale(String saleId) async {
    return await remoteDataSource.deleteSale(saleId);
  }

  @override
  Future<void> createSaleGroup(
      String groupTitle, List<String> saleIds) async {
    return await remoteDataSource.createSaleGroup(groupTitle, saleIds);
  }
}
