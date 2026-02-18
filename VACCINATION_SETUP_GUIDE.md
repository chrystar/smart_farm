# Vaccination Feature Setup Guide

## Overview
The vaccination feature provides comprehensive tracking of poultry vaccinations with:
- Pre-loaded IGC AGRO vaccination schedule
- Vaccination logging and history
- Push notifications for upcoming vaccines
- Integration with batch lifecycle

---

## 1. Database Setup

### Run the Migration
Execute the SQL migration in your Supabase database:

```bash
# In Supabase dashboard → SQL Editor
# Copy and run: supabase/migrations/create_vaccination_tables.sql
```

This creates two tables:
- `vaccine_schedules` - Defines when each vaccine should be given
- `vaccination_logs` - Records actual vaccinations administered

---

## 2. Dependency Injection Setup

Add vaccination feature initialization to your `main.dart`:

```dart
import 'package:smart_farm/features/vaccination/presentation/providers/vaccination_injection.dart';
import 'package:provider/provider.dart';

void main() async {
  // ... existing setup code ...
  
  // Initialize vaccination feature
  setupVaccinationInjection();
  
  runApp(const MyApp());
}
```

Also add VaccinationProvider to your providers in `main.dart`:

```dart
MultiProvider(
  providers: [
    // ... existing providers ...
    ChangeNotifierProvider(
      create: (_) => getIt<VaccinationProvider>(),
    ),
  ],
  child: const App(),
)
```

---

## 3. Initialize Notifications

Add to your main app initialization (typically in `main.dart` or `app.dart`):

```dart
import 'package:smart_farm/features/vaccination/presentation/utils/vaccination_initializer.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize vaccination system after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeVaccinationSystem(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Your app widget...
  }
}
```

---

## 4. Integrate into Batch Detail Screen

Add vaccination tab to your batch detail screen:

```dart
import 'package:smart_farm/features/vaccination/presentation/widgets/vaccination_tab_widget.dart';

class BatchDetailScreen extends StatelessWidget {
  final Batch batch;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Adjust based on your tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(batch.name),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Mortality'),
              Tab(text: 'Vaccinations'), // Add this
              Tab(text: 'Logs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ... existing tabs ...
            VaccinationTabWidget(
              batchId: batch.id,
              batchName: batch.name,
              batchStartDate: batch.startDate,
            ),
            // ... existing tabs ...
          ],
        ),
      ),
    );
  }
}
```

---

## 5. Using the Feature

### Load Default Schedule
When creating or viewing a batch, users can load the default IGC AGRO schedule:

```dart
// In any screen with VaccinationProvider
context.read<VaccinationProvider>().loadDefaultSchedules();
```

### Log a Vaccination
Record when a vaccine was administered:

```dart
import 'package:smart_farm/features/vaccination/domain/entities/vaccination_log.dart';

final log = VaccinationLog(
  id: 'unique_id',
  userId: currentUserId,
  batchId: batchId,
  scheduleId: scheduleId,
  vaccineType: VaccineType.newcastle,
  vaccineName: 'Newcastle (ND)',
  route: VaccineRoute.eyeDrop,
  dosage: '1 drop each eye',
  administeredDate: DateTime.now(),
  expectedDate: expectedDate,
  administeredBy: 'Farmer Name',
  notes: 'Any observations',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await context.read<VaccinationProvider>().logVaccination(log);
```

### Schedule Reminders for a Batch
When starting a new batch, schedule vaccination reminders:

```dart
import 'package:smart_farm/features/vaccination/presentation/utils/vaccination_initializer.dart';

await setupBatchVaccinationReminders(
  context,
  batchId: batch.id,
  batchStartDate: batch.startDate,
);
```

---

## 6. Available Vaccines (Default Schedule)

| Day | Vaccine | Route | Dosage |
|-----|---------|-------|--------|
| 1 | Newcastle (ND) | Eye Drop | 1 drop each eye |
| 1 | IBD (Gumboro) | Oral | 1 drop |
| 4 | Coccidiostat | Oral | As per recommendation |
| 7 | Gumboro Booster | Water | 1 dose |
| 10 | Fowl Pox | Wing Web | Slight scarification |
| 14 | Newcastle Booster | Eye Drop | 1 drop each eye |
| 21 | Infectious Coryza | I.M. | 0.5 ml |
| 28 | Gumboro Booster | Water | 1 dose |
| 35 | Fowl Typhoid | I.M. | 0.5 ml |
| 42 | Newcastle Final | Eye Drop | 1 drop each eye |

---

## 7. Customization

### Add Custom Vaccines
Create custom schedules programmatically:

```dart
import 'package:smart_farm/features/vaccination/domain/entities/vaccine_schedule.dart';

final customSchedule = VaccineSchedule(
  id: 'custom_id',
  userId: currentUserId,
  batchId: batchId,
  vaccineType: VaccineType.other,
  vaccineName: 'Custom Vaccine',
  ageInDays: 50,
  route: VaccineRoute.intramuscular,
  dosage: '1 ml',
  notes: 'Custom notes',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await context.read<VaccinationProvider>().createSchedule(customSchedule);
```

### Modify Notification Timing
Edit `vaccination_notification_service.dart` to change reminder days:

```dart
// Change from 1 day before to 3 days before
final reminderDate = scheduledDate.subtract(const Duration(days: 3));
```

---

## 8. Testing

### Test Notifications
```dart
import 'package:smart_farm/features/vaccination/domain/services/vaccination_notification_service.dart';

// Show immediate test notification
await VaccinationNotificationService.showTestNotification();
```

### Verify Database
Check if tables were created successfully:
```sql
SELECT * FROM vaccine_schedules LIMIT 1;
SELECT * FROM vaccination_logs LIMIT 1;
```

---

## 9. Offline Support

The vaccination feature automatically works offline:
- Schedules and logs are cached locally via Hive
- Changes sync when reconnected
- Banner shows "You are offline - Changes will sync when reconnected"

---

## 10. Architecture Overview

```
features/vaccination/
├── domain/
│   ├── entities/ (VaccineSchedule, VaccinationLog)
│   ├── repositories/ (abstract interface)
│   ├── usecases/ (business logic)
│   └── services/ (notifications)
├── data/
│   ├── datasources/ (Supabase API)
│   ├── models/ (JSON serialization)
│   └── repositories/ (implementation)
└── presentation/
    ├── pages/ (VaccinationSchedulePage)
    ├── providers/ (VaccinationProvider, injection)
    ├── widgets/ (VaccineScheduleCard, VaccinationTabWidget)
    └── utils/ (initialization)
```

---

## Troubleshooting

### Notifications not showing?
- Check permissions in `AndroidManifest.xml` and `Info.plist`
- Verify timezone configuration in `main.dart`
- Test with `showTestNotification()`

### Schedules not loading?
- Verify Supabase tables exist
- Check RLS policies are correctly set
- Verify user_id is being passed correctly

### Offline sync not working?
- Check Hive boxes are initialized in `OfflineSyncService`
- Verify connectivity_plus is detecting network changes
- Check that user is authenticated before syncing

---

## Next Steps

1. ✅ Run Supabase migration
2. ✅ Update `main.dart` with injection and initialization
3. ✅ Add VaccinationTabWidget to batch detail screen
4. ✅ Test loading default schedule
5. ✅ Test vaccination logging
6. ✅ Test push notifications
7. ✅ Deploy to production

For questions, refer to domain entities and repository interface for complete API.
