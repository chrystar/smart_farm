import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/services/supabase_service.dart';
import 'package:smart_farm/core/routing/app_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/authentication/di/auth_injection.dart';
import 'features/onboarding/presentation/provider/onboarding_provider.dart';
import 'features/batch/presentation/provider/batch_injection.dart';
import 'features/dashboard/presentation/provider/dashboard_injection.dart';
import 'features/settings/presentation/provider/settings_injection.dart';
import 'features/expenses/presentation/provider/expense_injection.dart';
import 'features/sales/presentation/provider/sales_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Google Fonts runtime fetching
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize Supabase
  try {
    await SupabaseService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Initialize Settings (SharedPreferences + Notifications)
  await SettingsInjection.initialize();

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
