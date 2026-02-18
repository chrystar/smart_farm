import 'package:equatable/equatable.dart';
import 'vaccine_schedule.dart';

class VaccinationLog extends Equatable {
  final String id;
  final String userId;
  final String batchId;
  final String scheduleId;
  final VaccineType vaccineType;
  final String vaccineName;
  final VaccineRoute route;
  final String dosage;
  final DateTime administeredDate;
  final DateTime expectedDate; // When it was supposed to be given
  final String? administeredBy;
  final String? notes;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VaccinationLog({
    required this.id,
    required this.userId,
    required this.batchId,
    required this.scheduleId,
    required this.vaccineType,
    required this.vaccineName,
    required this.route,
    required this.dosage,
    required this.administeredDate,
    required this.expectedDate,
    this.administeredBy,
    this.notes,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    batchId,
    scheduleId,
    vaccineType,
    vaccineName,
    route,
    dosage,
    administeredDate,
    expectedDate,
    administeredBy,
    notes,
    isCompleted,
    createdAt,
    updatedAt,
  ];
}
