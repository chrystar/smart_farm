import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vaccine_schedule_model.dart';
import '../models/vaccination_log_model.dart';

abstract class VaccinationRemoteDataSource {
  Future<List<VaccineScheduleModel>> getVaccineSchedules(String batchId);
  Future<VaccineScheduleModel> createVaccineSchedule(Map<String, dynamic> data);
  Future<VaccineScheduleModel> updateVaccineSchedule(String scheduleId, Map<String, dynamic> data);
  Future<void> deleteVaccineSchedule(String scheduleId);
  
  Future<List<VaccinationLogModel>> getVaccinationLogs(String batchId);
  Future<VaccinationLogModel> logVaccination(Map<String, dynamic> data);
  Future<VaccinationLogModel> updateVaccinationLog(String logId, Map<String, dynamic> data);
  Future<void> deleteVaccinationLog(String logId);
  
  Future<List<VaccineScheduleModel>> getDefaultSchedules();
  Future<void> createSchedulesForBatch(String batchId, String userId);
}

class VaccinationRemoteDataSourceImpl implements VaccinationRemoteDataSource {
  final SupabaseClient supabaseClient;
  
  VaccinationRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<VaccineScheduleModel>> getVaccineSchedules(String batchId) async {
    try {
      final response = await supabaseClient
          .from('vaccine_schedules')
          .select()
          .eq('batch_id', batchId)
          .order('age_in_days', ascending: true);

      return (response as List)
          .map((json) => VaccineScheduleModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch vaccine schedules: $e');
    }
  }

  @override
  Future<VaccineScheduleModel> createVaccineSchedule(Map<String, dynamic> data) async {
    try {
      final response = await supabaseClient
          .from('vaccine_schedules')
          .insert(data)
          .select()
          .single();

      return VaccineScheduleModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create vaccine schedule: $e');
    }
  }

  @override
  Future<VaccineScheduleModel> updateVaccineSchedule(String scheduleId, Map<String, dynamic> data) async {
    try {
      final response = await supabaseClient
          .from('vaccine_schedules')
          .update(data)
          .eq('id', scheduleId)
          .select()
          .single();

      return VaccineScheduleModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update vaccine schedule: $e');
    }
  }

  @override
  Future<void> deleteVaccineSchedule(String scheduleId) async {
    try {
      await supabaseClient
          .from('vaccine_schedules')
          .delete()
          .eq('id', scheduleId);
    } catch (e) {
      throw Exception('Failed to delete vaccine schedule: $e');
    }
  }

  @override
  Future<List<VaccinationLogModel>> getVaccinationLogs(String batchId) async {
    try {
      final response = await supabaseClient
          .from('vaccination_logs')
          .select()
          .eq('batch_id', batchId)
          .order('administered_date', ascending: false);

      return (response as List)
          .map((json) => VaccinationLogModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch vaccination logs: $e');
    }
  }

  @override
  Future<VaccinationLogModel> logVaccination(Map<String, dynamic> data) async {
    try {
      final response = await supabaseClient
          .from('vaccination_logs')
          .insert(data)
          .select()
          .single();

      return VaccinationLogModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to log vaccination: $e');
    }
  }

  @override
  Future<VaccinationLogModel> updateVaccinationLog(String logId, Map<String, dynamic> data) async {
    try {
      final response = await supabaseClient
          .from('vaccination_logs')
          .update(data)
          .eq('id', logId)
          .select()
          .single();

      return VaccinationLogModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update vaccination log: $e');
    }
  }

  @override
  Future<void> deleteVaccinationLog(String logId) async {
    try {
      await supabaseClient
          .from('vaccination_logs')
          .delete()
          .eq('id', logId);
    } catch (e) {
      throw Exception('Failed to delete vaccination log: $e');
    }
  }

  @override
  Future<List<VaccineScheduleModel>> getDefaultSchedules() async {
    // Return pre-defined complete health management schedule with duration
    final defaultSchedules = [
      {
        'id': 'default_1',
        'vaccine_type': 'other',
        'vaccine_name': 'Glucose',
        'age_in_days': 1,
        'duration_days': 1,
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Energy boost',
      },
      {
        'id': 'default_2',
        'vaccine_type': 'other',
        'vaccine_name': 'Antibiotic + Vitamin',
        'age_in_days': 2,
        'duration_days': 4, // Days 2-5
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Immune support',
      },
      {
        'id': 'default_3',
        'vaccine_type': 'newcastle',
        'vaccine_name': 'Vaccine',
        'age_in_days': 6,
        'duration_days': 1,
        'route': 'eyeDrop',
        'dosage': 'As per vaccine protocol',
        'notes': 'Primary vaccination',
      },
      {
        'id': 'default_4',
        'vaccine_type': 'coccidiostat',
        'vaccine_name': 'Coccidiostat',
        'age_in_days': 7,
        'duration_days': 3, // Days 7-9
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Disease prevention',
      },
      {
        'id': 'default_5',
        'vaccine_type': 'other',
        'vaccine_name': 'Vitamin',
        'age_in_days': 10,
        'duration_days': 1,
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Nutritional support',
      },
      {
        'id': 'default_6',
        'vaccine_type': 'ibd',
        'vaccine_name': 'Vaccine',
        'age_in_days': 11,
        'duration_days': 1,
        'route': 'eyeDrop',
        'dosage': 'As per vaccine protocol',
        'notes': 'Vaccination',
      },
      {
        'id': 'default_7',
        'vaccine_type': 'other',
        'vaccine_name': 'Vitamin',
        'age_in_days': 12,
        'duration_days': 1,
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Nutritional support',
      },
      {
        'id': 'default_8',
        'vaccine_type': 'other',
        'vaccine_name': 'Antibiotics',
        'age_in_days': 13,
        'duration_days': 4, // Days 13-16
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Disease prevention',
      },
      {
        'id': 'default_9',
        'vaccine_type': 'coccidiostat',
        'vaccine_name': 'Coccidiostat',
        'age_in_days': 17,
        'duration_days': 3, // Days 17-19
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Disease prevention',
      },
      {
        'id': 'default_10',
        'vaccine_type': 'other',
        'vaccine_name': 'Vitamin',
        'age_in_days': 20,
        'duration_days': 1,
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Nutritional support',
      },
      {
        'id': 'default_11',
        'vaccine_type': 'newcastle',
        'vaccine_name': 'Vaccine',
        'age_in_days': 21,
        'duration_days': 1,
        'route': 'eyeDrop',
        'dosage': 'As per vaccine protocol',
        'notes': 'Vaccination',
      },
      {
        'id': 'default_12',
        'vaccine_type': 'other',
        'vaccine_name': 'Antibiotics',
        'age_in_days': 22,
        'duration_days': 6, // Days 22-27
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Disease prevention',
      },
      {
        'id': 'default_13',
        'vaccine_type': 'newcastle',
        'vaccine_name': 'Vaccine',
        'age_in_days': 28,
        'duration_days': 1,
        'route': 'eyeDrop',
        'dosage': 'As per vaccine protocol',
        'notes': 'Vaccination',
      },
      {
        'id': 'default_14',
        'vaccine_type': 'other',
        'vaccine_name': 'Vitamin',
        'age_in_days': 29,
        'duration_days': 1,
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Nutritional support',
      },
      {
        'id': 'default_15',
        'vaccine_type': 'other',
        'vaccine_name': 'Acidifier',
        'age_in_days': 30,
        'duration_days': 5, // Days 30-34
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Gut health',
      },
      {
        'id': 'default_16',
        'vaccine_type': 'coccidiostat',
        'vaccine_name': 'Coccidiostat',
        'age_in_days': 35,
        'duration_days': 5, // Days 35-39
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Disease prevention',
      },
      {
        'id': 'default_17',
        'vaccine_type': 'other',
        'vaccine_name': 'Dewormer',
        'age_in_days': 40,
        'duration_days': 1,
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Parasite control',
      },
      {
        'id': 'default_18',
        'vaccine_type': 'other',
        'vaccine_name': 'Vitamin',
        'age_in_days': 41,
        'duration_days': 6, // Days 41-46
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Nutritional support',
      },
      {
        'id': 'default_19',
        'vaccine_type': 'other',
        'vaccine_name': 'Acidifier',
        'age_in_days': 47,
        'duration_days': 4, // Days 47-50
        'route': 'water',
        'dosage': 'As per recommendation',
        'notes': 'Gut health',
      },
      {
        'id': 'default_20',
        'vaccine_type': 'other',
        'vaccine_name': 'Symptomatic Treatment',
        'age_in_days': 51,
        'duration_days': 1,
        'route': 'water',
        'dosage': 'As needed',
        'notes': 'As symptoms appear',
      },
    ];

    return defaultSchedules
        .map((json) => VaccineScheduleModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> createSchedulesForBatch(String batchId, String userId) async {
    try {
      final defaultSchedules = await getDefaultSchedules();
      
      // Convert to insertable records
      final schedulesToInsert = defaultSchedules.map((schedule) {
        return {
          'user_id': userId,
          'batch_id': batchId,
          'vaccine_type': schedule.vaccineType.toString().split('.').last,
          'vaccine_name': schedule.vaccineName,
          'age_in_days': schedule.ageInDays,
          'route': schedule.route.toString().split('.').last,
          'dosage': schedule.dosage,
          'notes': schedule.notes,
        };
      }).toList();

      await supabaseClient
          .from('vaccine_schedules')
          .insert(schedulesToInsert);
    } catch (e) {
      throw Exception('Failed to create schedules for batch: $e');
    }
  }
}
