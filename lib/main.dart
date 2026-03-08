import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:smart_farm/core/constants/revenuecat_constants.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:smart_farm/core/services/supabase_service.dart';
import 'package:smart_farm/core/routing/app_router.dart';
import 'package:smart_farm/core/services/vaccination_alarm_service.dart';
import 'package:smart_farm/features/settings/presentation/provider/settings_provider.dart';
import 'package:smart_farm/features/notification/services/notification_service.dart';
import 'package:smart_farm/features/notification/services/local_notification_service.dart';
import 'features/authentication/di/auth_injection.dart';
import 'features/onboarding/presentation/provider/onboarding_provider.dart';
import 'features/batch/presentation/provider/batch_injection.dart';
import 'features/dashboard/presentation/provider/dashboard_injection.dart';
import 'features/settings/presentation/provider/settings_injection.dart';
import 'features/expenses/presentation/provider/expense_injection.dart';
import 'features/sales/presentation/provider/sales_injection.dart';
import 'features/vaccination/presentation/providers/vaccination_injection.dart';
import 'features/subscription/subscription_provider.dart';
import 'features/subscription/revenuecat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Purchases.configure(PurchasesConfiguration(RevenueCatConfig.apiKey));

  // Initialize Supabase
  try {
    await SupabaseService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Initialize Settings (SharedPreferences + Notifications)
  await SettingsInjection.initialize();

  // Initialize Local Notifications
  try {
    await LocalNotificationService.initialize();
    debugPrint('Local notifications initialized');
  } catch (e) {
    debugPrint('Failed to initialize local notifications: $e');
  }

  // Initialize Vaccination Alarm Service
  try {
    await VaccinationAlarmService.initialize();
    await VaccinationAlarmService.scheduleDailyAlarm();
    debugPrint('Vaccination alarm scheduled for 6 AM daily');
  } catch (e) {
    debugPrint('Failed to initialize vaccination alarm: $e');
  }

  runApp(const MyApp());
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
        ChangeNotifierProvider(
          create: (_) {
            final service = NotificationService();
            service.loadNotifications();
            service.subscribeToNotifications();
            return service;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = SubscriptionProvider(RevenueCatService());
            provider.initialize();
            return provider;
          },
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          final themeMode = settingsProvider.preferences?.themeMode ?? 'system';

          return MaterialApp.router(
            title: 'Smart Farm',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryGreen,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeMode == 'light'
                ? ThemeMode.light
                : themeMode == 'dark'
                    ? ThemeMode.dark
                    : ThemeMode.system,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
