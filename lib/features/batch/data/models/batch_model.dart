import '../../domain/entities/batch.dart';

class BatchModel extends Batch {
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

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as String,
      name: json['name'] as String,
      birdType: _birdTypeFromString(json['bird_type'] as String),
      breed: json['breed'] as String?,
      expectedQuantity: json['expected_quantity'] as int,
      actualQuantity: json['actual_quantity'] as int?,
      status: _statusFromString(json['status'] as String),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      purchaseCost: json['purchase_cost'] != null
          ? (json['purchase_cost'] as num).toDouble()
          : null,
      currency: json['currency'] as String?,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bird_type': _birdTypeToString(birdType),
      'breed': breed,
      'expected_quantity': expectedQuantity,
      'actual_quantity': actualQuantity,
      'status': _statusToString(status),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'purchase_cost': purchaseCost,
      'currency': currency,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static BirdType _birdTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'broiler':
        return BirdType.broiler;
      case 'layer':
        return BirdType.layer;
      default:
        return BirdType.broiler;
    }
  }

  static String _birdTypeToString(BirdType type) {
    switch (type) {
      case BirdType.broiler:
        return 'broiler';
      case BirdType.layer:
        return 'layer';
    }
  }

  static BatchStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'planned':
        return BatchStatus.planned;
      case 'active':
        return BatchStatus.active;
      case 'completed':
        return BatchStatus.completed;
      default:
        return BatchStatus.planned;
    }
  }

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
      userId: batch.userId,
      createdAt: batch.createdAt,
      updatedAt: batch.updatedAt,
    );
  }
}
