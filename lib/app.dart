// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:smart_farm/core/widgets/connectivity_banner.dart';
import 'package:smart_farm/features/batch/presentation/screens/batch_list_screen.dart';
import 'package:smart_farm/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:smart_farm/features/expenses/presentation/pages/expenses_screen.dart';
import 'package:smart_farm/features/learning/presentation/screens/articles_screen.dart';
import 'package:smart_farm/features/learning/presentation/screens/creator_farmers_screen.dart';
import 'package:smart_farm/features/learning/presentation/screens/creator_signup_screen.dart';
import 'package:smart_farm/features/sales/presentation/pages/sales_list_screen.dart';
import 'package:smart_farm/features/subscription/subscription_provider.dart';
import 'package:smart_farm/features/subscription/subscription_screen.dart';

import 'package:smart_farm/features/settings/presentation/pages/settings_screen.dart';

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;
  Widget? _currentScreen;

  final _screens = const [
    DashboardScreen(),
    BatchListScreen(),
    ExpensesScreen(),
    SalesListScreen(),
    SettingsScreen(),
  ];

  final _navItems = const [
    (icon: Icons.dashboard, label: 'Home'),
    (icon: Icons.agriculture, label: 'Batches'),
    (icon: Icons.receipt_long, label: 'Expenses'),
    (icon: Icons.store, label: 'Sales'),
    (icon: Icons.settings, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _currentScreen = _screens[_currentIndex];
  }



  

 

  @override
  Widget build(BuildContext context) {
    

    // Mobile: Bottom navigation
    return Scaffold(
    
      body: ConnectivityBanner(
        child: _currentScreen ?? _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primaryGreenSwatch,
        unselectedItemColor: AppColors.secondaryText,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() {
            _currentIndex = i;
            _currentScreen = null; // Reset custom screen
          });
        },
        items: _navItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }


}
