import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/services/supabase_service.dart';
import 'package:smart_farm/core/routing/app_router.dart';
import 'package:smart_farm/core/services/vaccination_alarm_service.dart';
import 'features/authentication/di/auth_injection.dart';
import 'features/onboarding/presentation/provider/onboarding_provider.dart';
import 'features/batch/presentation/provider/batch_injection.dart';
import 'features/dashboard/presentation/provider/dashboard_injection.dart';
import 'features/settings/presentation/provider/settings_injection.dart';
import 'features/expenses/presentation/provider/expense_injection.dart';
import 'features/sales/presentation/provider/sales_injection.dart';
import 'features/vaccination/presentation/providers/vaccination_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  // Initialize Supabase
  try {
    await SupabaseService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Initialize Settings (SharedPreferences + Notifications)
  await SettingsInjection.initialize();

  // Initialize Vaccination Alarm Service
  try {
    await VaccinationAlarmService.initialize();
    await VaccinationAlarmService.scheduleDailyAlarm();
    debugPrint('Vaccination alarm scheduled for 6 AM daily');
  } catch (e) {
    debugPrint('Failed to initialize vaccination alarm: $e');
  }

  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2;
      },
      appRunner: () => runApp(const MyApp()),
    );
  } else {
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...AuthInjection.providers,
        ...BatchInjection.providers,
        ...DashboardInjection.providers,
        ...SettingsInjection.providers,
        ...ExpenseInjection.providers,
        ...SalesInjection.providers,
        ...VaccinationInjection.providers,
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: MaterialApp.router(
        title: 'Smart Farm',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
