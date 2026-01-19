import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/app_fonts.dart';
import 'package:smart_farm/core/constants/app_size.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:smart_farm/features/authentication/presentation/screens/login_screen.dart';
import 'package:smart_farm/features/authentication/presentation/screens/register_screen.dart';

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using LayoutBuilder to adapt layout based on available constraints
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FarmAgent',
          style: AppFonts.text24normal(context, fontWeight: FontWeight.bold, color: AppColors.primaryTextColor), // Use a valid TextStyle from AppFonts
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // You can use constraints.maxWidth, constraints.maxHeight, etc.
            // For demonstration, let's adjust padding and font size based on width
            double horizontalPadding = constraints.maxWidth > 600 ? 80 : 20;
            double titleFontSize = constraints.maxWidth > 600 ? 32 : 22;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: AppSizes.spaceXS(context), left: horizontalPadding, right: horizontalPadding),
                  child: Column(
                    children: [
                      Text(
                        'Welcome to Farm Agent',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: AppSizes.spaceM(context)),
                     const Text(
                        'Sign up or sign in below to manage, monitor and manage your poultry farm',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
               const SizedBox(height: 20),
                TabBar(
                  controller: tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  tabs: const[Tab(text: 'Login'), Tab(text: 'Sign Up')],
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: const [LoginScreen(), RegisterScreen()],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
