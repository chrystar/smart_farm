import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/app_fonts.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:smart_farm/core/constants/theme/app_theme.dart';
import 'package:smart_farm/features/authentication/presentation/screens/login_screen.dart';
import 'package:smart_farm/features/home.dart/presentation/widgets/home_screen.dart';
import 'package:smart_farm/features/onboarding/data/onboarding_model_impl.dart';
import 'package:smart_farm/features/onboarding/presentation/screens/get_started.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final onboardingModelImpl = OnboardingModelImpl().onboard;
  final PageController pageController = PageController();
  int currentIndex = 0;

  void _onNext() {
    if (currentIndex < onboardingModelImpl.length - 1) {
      pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToHome();
    }
  }

  void _onSkip() {
    _goToHome();
  }

  void _goToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => GetStarted()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Poultriz-Point'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        titleTextStyle: AppFonts.text24normal(
          context,
          color: AppColors.primaryTextColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: onboardingModelImpl.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      
                        Container(
                          height: MediaQuery.of(context).size.height * 0.4,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                onboardingModelImpl[index].image,
                              ),
                            ),
                          ),
                        ),

                       Column(
                        children: [
                           Text(
                          onboardingModelImpl[index].title,
                          style: AppFonts.text20normal(context, color: AppColors.primaryText, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 18),
                        Text(
                          onboardingModelImpl[index].subdescription,
                          textAlign: TextAlign.center,
                          style: AppFonts.text12normal(context, color: AppColors.primaryText),
                        ),
                        ],
                       )
                      ],
                    );
                  },
                ),
              ),
              Column(
                //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                 
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                    ),
                    child: Text(
                      currentIndex == onboardingModelImpl.length - 1
                          ? 'Finish'
                          : 'Next',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 10),
                   Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.borderDivider, width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  
                    child:  TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      'Skip',
                      style: TextStyle(color: AppColors.primaryGreen),
                    ),
                  )),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
