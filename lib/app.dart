// lib/app.dart
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'Batches'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}





