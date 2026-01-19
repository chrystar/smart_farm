import 'package:equatable/equatable.dart';

class DailyRecord extends Equatable {
  final String id;
  final String batchId;
  final DateTime date;
  final int mortalityCount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyRecord({
    required this.id,
    required this.batchId,
    required this.date,
    required this.mortalityCount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  DailyRecord copyWith({
    String? id,
    String? batchId,
    DateTime? date,
    int? mortalityCount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyRecord(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      date: date ?? this.date,
      mortalityCount: mortalityCount ?? this.mortalityCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        batchId,
        date,
        mortalityCount,
        notes,
        createdAt,
        updatedAt,
      ];
}
