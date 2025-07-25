import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:smart_farm/core/constants/theme/app_theme.dart';
import 'package:smart_farm/core/constants/theme/theme_provider.dart';
import 'package:smart_farm/features/home.dart/presentation/widgets/home_screen.dart';
import 'package:smart_farm/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:smart_farm/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SmartFarm(),
    ),
  );
}

class SmartFarm extends StatelessWidget {
  const SmartFarm({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}

