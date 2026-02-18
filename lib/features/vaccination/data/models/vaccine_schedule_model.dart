import '../../domain/entities/vaccine_schedule.dart';

class VaccineScheduleModel extends VaccineSchedule {
  const VaccineScheduleModel({
    required super.id,
    required super.userId,
    required super.batchId,
    required super.vaccineType,
    required super.vaccineName,
    required super.ageInDays,
    super.durationDays = 1,
    required super.route,
    required super.dosage,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory VaccineScheduleModel.fromJson(Map<String, dynamic> json) {
    return VaccineScheduleModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      batchId: json['batch_id']?.toString() ?? '',
      vaccineType: VaccineType.values.firstWhere(
        (e) => e.name == json['vaccine_type'],
        orElse: () => VaccineType.other,
      ),
      vaccineName: json['vaccine_name']?.toString() ?? '',
      ageInDays: (json['age_in_days'] as num?)?.toInt() ?? 0,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 1,
      route: VaccineRoute.values.firstWhere(
        (e) => e.name == json['route'],
        orElse: () => VaccineRoute.other,
      ),
      dosage: json['dosage']?.toString() ?? '',
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'batch_id': batchId,
      'vaccine_type': vaccineType.name,
      'vaccine_name': vaccineName,
      'age_in_days': ageInDays,
      'duration_days': durationDays,
      'route': route.name,
      'dosage': dosage,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory VaccineScheduleModel.fromEntity(VaccineSchedule entity) {
    return VaccineScheduleModel(
      id: entity.id,
      userId: entity.userId,
      batchId: entity.batchId,
      vaccineType: entity.vaccineType,
      vaccineName: entity.vaccineName,
      ageInDays: entity.ageInDays,
      durationDays: entity.durationDays,
      route: entity.route,
      dosage: entity.dosage,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
