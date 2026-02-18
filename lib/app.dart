// lib/app.dart
import 'package:flutter/material.dart';
import 'package:smart_farm/core/widgets/connectivity_banner.dart';
import 'package:smart_farm/features/batch/presentation/screens/batch_list_screen.dart';
import 'package:smart_farm/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:smart_farm/features/expenses/presentation/pages/expenses_screen.dart';
import 'package:smart_farm/features/sales/presentation/pages/sales_list_screen.dart';

import 'package:smart_farm/features/settings/presentation/pages/settings_screen.dart';

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;

  final _screens = const [
    DashboardScreen(),
    BatchListScreen(),
    ExpensesScreen(),
    SalesListScreen(),
    SettingsScreen(),
  ];

  final _navItems = const [
    (icon: Icons.dashboard, label: 'Dashboard'),
    (icon: Icons.agriculture, label: 'Batches'),
    (icon: Icons.receipt_long, label: 'Expenses'),
    (icon: Icons.store, label: 'Sales'),
    (icon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    if (isWeb) {
      // Desktop: Sidebar navigation
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            Expanded(
              child: ConnectivityBanner(
                child: _screens[_currentIndex],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile: Bottom navigation
    return Scaffold(
      body: ConnectivityBanner(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
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





