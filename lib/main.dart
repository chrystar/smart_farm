import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/features/authentication/presentation/screens/getstarted.dart';
import 'package:smart_farm/features/home.dart/presentation/screens/home_screen.dart';
import 'features/authentication/di/auth_injection.dart';
import 'features/authentication/presentation/provider/auth_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...AuthInjection.providers,
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Initialize auth state when app starts
          WidgetsBinding.instance.addPostFrameCallback((_) {
            authProvider.initializeAuth();
          });

          return MaterialApp(
            title: 'Smart Farm',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
              useMaterial3: true,
            ),
            home: authProvider.isAuthenticated 
              ? const HomeScreen()
              : const GetStartedScreen(),
          );
        },
      ),
    );
  }
}

