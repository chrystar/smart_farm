import '../../domain/entities/daily_record.dart';

class DailyRecordModel extends DailyRecord {
  const DailyRecordModel({
    required super.id,
    required super.batchId,
    required super.date,
    required super.mortalityCount,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DailyRecordModel.fromJson(Map<String, dynamic> json) {
    return DailyRecordModel(
      id: json['id'] as String,
      batchId: json['batch_id'] as String,
      date: DateTime.parse(json['date'] as String),
      mortalityCount: json['mortality_count'] as int,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'date': date.toIso8601String().split('T')[0], // Store date only
      'mortality_count': mortalityCount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DailyRecordModel.fromEntity(DailyRecord record) {
    return DailyRecordModel(
      id: record.id,
      batchId: record.batchId,
      date: record.date,
      mortalityCount: record.mortalityCount,
      notes: record.notes,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }
}
