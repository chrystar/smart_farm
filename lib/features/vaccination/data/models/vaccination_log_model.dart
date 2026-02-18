import '../../domain/entities/vaccination_log.dart';
import '../../domain/entities/vaccine_schedule.dart';

class VaccinationLogModel extends VaccinationLog {
  const VaccinationLogModel({
    required super.id,
    required super.userId,
    required super.batchId,
    required super.scheduleId,
    required super.vaccineType,
    required super.vaccineName,
    required super.route,
    required super.dosage,
    required super.administeredDate,
    required super.expectedDate,
    super.administeredBy,
    super.notes,
    super.isCompleted,
    required super.createdAt,
    required super.updatedAt,
  });

  factory VaccinationLogModel.fromJson(Map<String, dynamic> json) {
    return VaccinationLogModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      batchId: json['batch_id']?.toString() ?? '',
      scheduleId: json['schedule_id']?.toString() ?? '',
      vaccineType: VaccineType.values.firstWhere(
        (e) => e.name == json['vaccine_type'],
        orElse: () => VaccineType.other,
      ),
      vaccineName: json['vaccine_name']?.toString() ?? '',
      route: VaccineRoute.values.firstWhere(
        (e) => e.name == json['route'],
        orElse: () => VaccineRoute.other,
      ),
      dosage: json['dosage']?.toString() ?? '',
      administeredDate: json['administered_date'] != null
          ? DateTime.parse(json['administered_date'] as String)
          : DateTime.now(),
      expectedDate: json['expected_date'] != null
          ? DateTime.parse(json['expected_date'] as String)
          : DateTime.now(),
      administeredBy: json['administered_by']?.toString(),
      notes: json['notes']?.toString(),
      isCompleted: (json['is_completed'] as bool?) ?? false,
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
      'schedule_id': scheduleId,
      'vaccine_type': vaccineType.name,
      'vaccine_name': vaccineName,
      'route': route.name,
      'dosage': dosage,
      'administered_date': administeredDate.toIso8601String(),
      'expected_date': expectedDate.toIso8601String(),
      'administered_by': administeredBy,
      'notes': notes,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory VaccinationLogModel.fromEntity(VaccinationLog entity) {
    return VaccinationLogModel(
      id: entity.id,
      userId: entity.userId,
      batchId: entity.batchId,
      scheduleId: entity.scheduleId,
      vaccineType: entity.vaccineType,
      vaccineName: entity.vaccineName,
      route: entity.route,
      dosage: entity.dosage,
      administeredDate: entity.administeredDate,
      expectedDate: entity.expectedDate,
      administeredBy: entity.administeredBy,
      notes: entity.notes,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
