import 'package:equatable/equatable.dart';

enum SaleType {
  birds,
  eggs,
  manure,
  other,
}

enum PaymentStatus {
  paid,
  pending,
  partiallyPaid,
}

extension SaleTypeExtension on SaleType {
  String get displayName {
    switch (this) {
      case SaleType.birds:
        return 'Birds';
      case SaleType.eggs:
        return 'Eggs';
      case SaleType.manure:
        return 'Manure';
      case SaleType.other:
        return 'Other';
    }
  }
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';
    }
  }

  String get badge {
    switch (this) {
      case PaymentStatus.paid:
        return 'P';
      case PaymentStatus.pending:
        return '⏱';
      case PaymentStatus.partiallyPaid:
        return '◐';
    }
  }
}

class Sale extends Equatable {
  final String id;
  final String userId;
  final String batchId;
  final SaleType saleType;
  final int quantity;
  final double pricePerUnit;
  final double totalAmount;
  final String currency;
  final DateTime saleDate;
  final String? buyerName;
  final PaymentStatus paymentStatus;
  final String? notes;
  final String? groupId;
  final String? groupTitle;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sale({
    required this.id,
    required this.userId,
    required this.batchId,
    required this.saleType,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalAmount,
    required this.currency,
    required this.saleDate,
    this.buyerName,
    required this.paymentStatus,
    this.notes,
    this.groupId,
    this.groupTitle,
    required this.createdAt,
    required this.updatedAt,
  });

  Sale copyWith({
    String? id,
    String? userId,
    String? batchId,
    SaleType? saleType,
    int? quantity,
    double? pricePerUnit,
    double? totalAmount,
    String? currency,
    DateTime? saleDate,
    String? buyerName,
    PaymentStatus? paymentStatus,
    String? notes,
    String? groupId,
    String? groupTitle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sale(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      batchId: batchId ?? this.batchId,
      saleType: saleType ?? this.saleType,
      quantity: quantity ?? this.quantity,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      saleDate: saleDate ?? this.saleDate,
      buyerName: buyerName ?? this.buyerName,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      groupId: groupId ?? this.groupId,
      groupTitle: groupTitle ?? this.groupTitle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    batchId,
    saleType,
    quantity,
    pricePerUnit,
    totalAmount,
    currency,
    saleDate,
    buyerName,
    paymentStatus,
    notes,
    groupId,
    groupTitle,
    createdAt,
    updatedAt,
  ];
}
