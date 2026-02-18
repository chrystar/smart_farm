import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/features/vaccination/domain/services/vaccination_notification_service.dart';
import 'package:smart_farm/features/vaccination/presentation/providers/vaccination_provider.dart';


/// Initialize vaccination system on app startup
Future<void> initializeVaccinationSystem(BuildContext context) async {
  // Initialize notification service
  await VaccinationNotificationService.initialize();

  // You can set up any other initialization logic here
  // For example: loading active batches and scheduling reminders
  debugPrint('✅ Vaccination system initialized');
}

/// Load and schedule reminders for a specific batch
Future<void> setupBatchVaccinationReminders(
  BuildContext context, {
  required String batchId,
  required DateTime batchStartDate,
}) async {
  try {
    // Load schedules for this batch
    await context.read<VaccinationProvider>().loadSchedules(batchId);

    // Get the schedules
    final schedules = context.read<VaccinationProvider>().schedules;

    // Schedule all reminders
    await VaccinationNotificationService.scheduleAllReminders(
      batchId: batchId,
      schedules: schedules,
      batchStartDate: batchStartDate,
    );

    debugPrint('✅ Vaccination reminders scheduled for batch: $batchId');
  } catch (e) {
    debugPrint('❌ Error scheduling reminders: $e');
  }
}
