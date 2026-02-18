import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/app.dart';
import 'package:smart_farm/core/services/preferences_service.dart';
import 'package:smart_farm/features/authentication/presentation/provider/auth_provider.dart';
import 'package:smart_farm/features/authentication/presentation/screens/getstarted.dart';
import 'package:smart_farm/features/authentication/presentation/screens/login_screen.dart';
import 'package:smart_farm/features/authentication/presentation/screens/register_screen.dart';
import 'package:smart_farm/features/batch/presentation/screens/batch_detail_screen.dart';
import 'package:smart_farm/features/batch/presentation/screens/batch_list_screen.dart';
import 'package:smart_farm/features/batch/presentation/screens/create_batch_screen.dart';
import 'package:smart_farm/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:smart_farm/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:smart_farm/features/settings/presentation/pages/about_screen.dart';
import 'package:smart_farm/features/settings/presentation/pages/notification_settings_screen.dart';
import 'package:smart_farm/features/settings/presentation/pages/profile_screen.dart';
import 'package:smart_farm/features/settings/presentation/pages/settings_screen.dart';



class AppRouter {
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String getStartedRoute = '/get-started';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String appRoute = '/app';
  static const String dashboardRoute = '/dashboard';
  static const String batchesRoute = '/batches';
  static const String createBatchRoute = '/batches/create';
  static const String settingsRoute = '/settings';
  static const String profileRoute = '/settings/profile';
  static const String notificationSettingsRoute = '/settings/notifications';
  static const String aboutRoute = '/settings/about';

  static final GoRouter router = GoRouter(
    initialLocation: splashRoute,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: splashRoute,
        name: 'splash',
        builder: (context, state) => const SplashScreenRouter(),
      ),
      GoRoute(
        path: onboardingRoute,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: getStartedRoute,
        name: 'getStarted',
        builder: (context, state) => const GetStartedScreen(),
      ),
      GoRoute(
        path: loginRoute,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: registerRoute,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: appRoute,
        name: 'app',
        builder: (context, state) => const App(),
      ),
      GoRoute(
        path: dashboardRoute,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: batchesRoute,
        name: 'batches',
        builder: (context, state) => const BatchListScreen(),
      ),
      GoRoute(
        path: createBatchRoute,
        name: 'createBatch',
        builder: (context, state) => const CreateBatchScreen(),
      ),
      GoRoute(
        path: '/batches/:id',
        name: 'batchDetail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BatchDetailScreen(batchId: id);
        },
      ),
      GoRoute(
        path: settingsRoute,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: profileRoute,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: notificationSettingsRoute,
        name: 'notificationSettings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: aboutRoute,
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),

    ],
  );

  /// Redirect logic to handle onboarding, authentication, and initial route
  static String? _redirect(BuildContext context, GoRouterState state) {
    // Allow navigation to splash/onboarding/login/register without checks
    if (state.uri.path == splashRoute ||
        state.uri.path == onboardingRoute ||
        state.uri.path == loginRoute ||
        state.uri.path == registerRoute) {
      return null;
    }

    return null;
  }
}

/// Splash screen that handles initial routing logic
class SplashScreenRouter extends StatefulWidget {
  const SplashScreenRouter({super.key});

  @override
  State<SplashScreenRouter> createState() => _SplashScreenRouterState();
}

class _SplashScreenRouterState extends State<SplashScreenRouter> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // allow splash to breathe a little
    await Future.delayed(const Duration(milliseconds: 300));

    final prefs = PreferencesService();
    final hasOnboarded = await prefs.getHasOnboarded();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.initializeAuth();

    if (!mounted) return;

    if (!hasOnboarded) {
      context.go(AppRouter.onboardingRoute);
    } else if (auth.isAuthenticated) {
      context.go(AppRouter.appRoute);
    } else {
      context.go(AppRouter.getStartedRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'Smart Farm',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
