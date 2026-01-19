import '../../domain/entities/sale.dart';

abstract class SalesRepository {
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
  });

  Future<List<Sale>> getSales(String userId);
  Future<List<Sale>> getBatchSales(String batchId);
  Future<void> updatePaymentStatus(String saleId, PaymentStatus status);
  Future<void> deleteSale(String saleId);
  Future<void> createSaleGroup(String groupTitle, List<String> saleIds);
}
