import 'package:equatable/equatable.dart';

enum VaccineType {
  newcastle,
  ibd, // Infectious Bursal Disease (Gumboro)
  fowlPox,
  infectiousCoryza,
  fowlTyphoid,
  coccidiostat,
  other
}

enum VaccineRoute {
  eyeDrop,
  nasal,
  oral,
  water,
  intramuscular,
  wingWeb,
  other
}

class VaccineSchedule extends Equatable {
  final String id;
  final String userId;
  final String batchId;
  final VaccineType vaccineType;
  final String vaccineName;
  final int ageInDays; // Age at which vaccine should be given
  final int durationDays; // Number of days the medication should be administered
  final VaccineRoute route;
  final String dosage;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VaccineSchedule({
    required this.id,
    required this.userId,
    required this.batchId,
    required this.vaccineType,
    required this.vaccineName,
    required this.ageInDays,
    this.durationDays = 1,
    required this.route,
    required this.dosage,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    batchId,
    vaccineType,
    vaccineName,
    ageInDays,
    durationDays,
    route,
    dosage,
    notes,
    createdAt,
    updatedAt,
  ];
}
