import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/constants/app_fonts.dart';
import 'package:smart_farm/core/constants/app_size.dart';
import 'package:smart_farm/core/constants/theme/theme_provider.dart';
import 'package:smart_farm/features/authentication/presentation/provider/auth_provider.dart';
import 'package:smart_farm/features/authentication/presentation/screens/getstarted.dart';
import 'package:smart_farm/features/authentication/presentation/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (mounted) {
      // Navigate to login screen and remove all previous routes
      Navigator.push(context, MaterialPageRoute(builder: (context) => GetStartedScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                showModelBottomSheet(context);
              });
            },
            icon: Icon(Icons.mode),
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(children: [Text('data')]),
    );
  }
}

void showModelBottomSheet(BuildContext context) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.3,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.paddingL(context)),
            child: Column(
              children: [
                ListTile(
                  leading: Text(
                    'Dark mode',
                    style: AppFonts.text14normal(context),
                  ),
                  trailing: Checkbox(
                    shape: CircleBorder(),
                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (bool? value) {
                      if (value != null) {
                        themeProvider.setTheme(
                          value ? ThemeMode.dark : ThemeMode.light,
                        );
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                ListTile(
                  leading: Text(
                    'Light mode',
                    style: AppFonts.text14normal(context),
                  ),
                  trailing: Checkbox(
                    shape: CircleBorder(),
                    value: themeProvider.themeMode == ThemeMode.light,
                    onChanged: (bool? value) {
                      if (value != null) {
                        themeProvider.setTheme(
                          value ? ThemeMode.light : ThemeMode.dark,
                        );
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
