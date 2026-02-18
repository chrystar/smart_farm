import 'package:flutter/material.dart';
import '../../domain/entities/vaccine_schedule.dart';
import '../../domain/entities/vaccination_log.dart';
import '../../domain/repositories/vaccination_repository.dart';
import '../../domain/usecases/get_vaccine_schedules.dart';
import '../../domain/usecases/create_vaccine_schedule.dart';
import '../../domain/usecases/log_vaccination.dart';
import '../../domain/usecases/get_default_schedules.dart';

class VaccinationProvider extends ChangeNotifier {
  final VaccinationRepository repository;

  VaccinationProvider({required this.repository});

  List<VaccineSchedule> _schedules = [];
  List<VaccinationLog> _logs = [];
  String? _error;
  bool _isLoading = false;

  List<VaccineSchedule> get schedules => _schedules;
  List<VaccinationLog> get logs => _logs;
  String? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> loadSchedules(String batchId) async {
    _setLoading(true);
    _setError(null);

    final result = await GetVaccineSchedules(repository).call(batchId);
    result.fold(
      (failure) => _setError(failure.message),
      (schedules) {
        _schedules = schedules;
        notifyListeners();
      },
    );

    _setLoading(false);
  }

  Future<void> loadDefaultSchedules() async {
    _setLoading(true);
    _setError(null);

    final result = await GetDefaultSchedules(repository).call();
    result.fold(
      (failure) => _setError(failure.message),
      (schedules) {
        _schedules = schedules;
        notifyListeners();
      },
    );

    _setLoading(false);
  }

  Future<void> createSchedule(VaccineSchedule schedule) async {
    _setError(null);

    final result = await CreateVaccineSchedule(repository).call(schedule);
    result.fold(
      (failure) => _setError(failure.message),
      (newSchedule) {
        _schedules.add(newSchedule);
        notifyListeners();
      },
    );
  }

  Future<void> loadVaccinationLogs(String batchId) async {
    _setLoading(true);
    _setError(null);

    final result = await repository.getVaccinationLogs(batchId);
    result.fold(
      (failure) => _setError(failure.message),
      (logs) {
        _logs = logs;
        notifyListeners();
      },
    );

    _setLoading(false);
  }

  Future<void> logVaccination(VaccinationLog log) async {
    _setError(null);

    final result = await LogVaccination(repository).call(log);
    result.fold(
      (failure) => _setError(failure.message),
      (newLog) {
        _logs.add(newLog);
        notifyListeners();
      },
    );
  }

  Future<void> deleteVaccinationLog(String logId) async {
    _setError(null);

    final result = await repository.deleteVaccinationLog(logId);
    result.fold(
      (failure) => _setError(failure.message),
      (_) {
        _logs.removeWhere((log) => log.id == logId);
        notifyListeners();
      },
    );
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
