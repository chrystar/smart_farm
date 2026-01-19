import '../../domain/entities/sale.dart';
import '../../domain/repositories/sales_repository.dart';

class RecordSaleUseCase {
  final SalesRepository repository;

  RecordSaleUseCase(this.repository);

  Future<Sale> call({
    required String userId,
    required String batchId,
    required SaleType saleType,
    required int quantity,
    required double pricePerUnit,
    required String currency,
    required DateTime saleDate,
    String? buyerName,
    String? notes,
  }) {
    return repository.recordSale(
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
  }
}

class GetSalesUseCase {
  final SalesRepository repository;

  GetSalesUseCase(this.repository);

  Future<List<Sale>> call(String userId) {
    return repository.getSales(userId);
  }
}

class GetBatchSalesUseCase {
  final SalesRepository repository;

  GetBatchSalesUseCase(this.repository);

  Future<List<Sale>> call(String batchId) {
    return repository.getBatchSales(batchId);
  }
}

class UpdatePaymentStatusUseCase {
  final SalesRepository repository;

  UpdatePaymentStatusUseCase(this.repository);

  Future<void> call(String saleId, PaymentStatus status) {
    return repository.updatePaymentStatus(saleId, status);
  }
}

class DeleteSaleUseCase {
  final SalesRepository repository;

  DeleteSaleUseCase(this.repository);

  Future<void> call(String saleId) {
    return repository.deleteSale(saleId);
  }
}

class CreateSaleGroupUseCase {
  final SalesRepository repository;

  CreateSaleGroupUseCase(this.repository);

  Future<void> call(String groupTitle, List<String> saleIds) {
    return repository.createSaleGroup(groupTitle, saleIds);
  }
}
