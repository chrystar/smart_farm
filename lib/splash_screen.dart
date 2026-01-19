import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/app.dart';
import 'package:smart_farm/core/services/preferences_service.dart';
import 'package:smart_farm/features/authentication/presentation/provider/auth_provider.dart';
import 'package:smart_farm/features/authentication/presentation/screens/getstarted.dart';
import 'package:smart_farm/features/onboarding/presentation/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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

    Widget next;
    if (!hasOnboarded) {
      next = const OnboardingScreen();
    } else if (auth.isAuthenticated) {
      next = const App();
    } else {
      next = const GetStartedScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Example splash with logo and app name
  
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
