import 'package:equatable/equatable.dart';

enum BirdType { broiler, layer }

enum BatchStatus { planned, active, completed }

class Batch extends Equatable {
  final String id;
  final String name;
  final BirdType birdType;
  final String? breed;
  final int expectedQuantity;
  final int? actualQuantity;
  final BatchStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? purchaseCost;
  final String? currency;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Batch({
    required this.id,
    required this.name,
    required this.birdType,
    this.breed,
    required this.expectedQuantity,
    this.actualQuantity,
    required this.status,
    this.startDate,
    this.endDate,
    this.purchaseCost,
    this.currency,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate current live birds based on daily records
  int getCurrentLiveBirds(int totalMortality) {
    if (actualQuantity == null) return 0;
    return actualQuantity! - totalMortality;
  }

  // Calculate days since start (Day 1 = activation day)
  int? getDaysSinceStart() {
    if (startDate == null) return null;
    return DateTime.now().difference(startDate!).inDays + 1;
  }

  Batch copyWith({
    String? id,
    String? name,
    BirdType? birdType,
    String? breed,
    int? expectedQuantity,
    int? actualQuantity,
    BatchStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? purchaseCost,
    String? currency,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Batch(
      id: id ?? this.id,
      name: name ?? this.name,
      birdType: birdType ?? this.birdType,
      breed: breed ?? this.breed,
      expectedQuantity: expectedQuantity ?? this.expectedQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      purchaseCost: purchaseCost ?? this.purchaseCost,
      currency: currency ?? this.currency,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        birdType,
        breed,
        expectedQuantity,
        actualQuantity,
        status,
        startDate,
        endDate,
        purchaseCost,
        userId,
        createdAt,
        updatedAt,
      ];
}
