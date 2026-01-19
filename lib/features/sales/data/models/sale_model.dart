import '../../domain/entities/sale.dart';

class SaleModel extends Sale {
  SaleModel({
    required super.id,
    required super.userId,
    required super.batchId,
    required super.saleType,
    required super.quantity,
    required super.pricePerUnit,
    required super.totalAmount,
    required super.currency,
    required super.saleDate,
    super.buyerName,
    required super.paymentStatus,
    super.notes,
    super.groupId,
    super.groupTitle,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      batchId: json['batch_id'] as String,
      saleType: SaleType.values.firstWhere(
        (e) => e.name == json['sale_type'],
        orElse: () => SaleType.birds,
      ),
      quantity: json['quantity'] as int,
      pricePerUnit: (json['price_per_unit'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      saleDate: DateTime.parse(json['sale_date'] as String),
      buyerName: json['buyer_name'] as String?,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      notes: json['notes'] as String?,
      groupId: json['group_id'] as String?,
      groupTitle: json['group_title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'batch_id': batchId,
      'sale_type': saleType.name,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_amount': totalAmount,
      'currency': currency,
      'sale_date': saleDate.toIso8601String(),
      'buyer_name': buyerName,
      'payment_status': paymentStatus.name,
      'notes': notes,
      'group_id': groupId,
      'group_title': groupTitle,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
