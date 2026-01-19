import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/core/constants/app_fonts.dart';
import 'package:smart_farm/core/constants/theme/app_color.dart';
import 'package:smart_farm/core/routing/app_router.dart';
import 'package:smart_farm/core/services/preferences_service.dart';
import 'package:smart_farm/features/onboarding/presentation/provider/onboarding_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _onNext(OnboardingProvider provider, int totalPages) {
    if (provider.currentIndex < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      provider.nextPage(totalPages);
    } else {
      _goToGetStarted();
    }
  }

  void _onSkip() {
    _goToGetStarted();
  }

  void _goToGetStarted() async {
    await PreferencesService().setHasOnboarded(true);
    if (mounted) {
      context.go(AppRouter.getStartedRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),
      child: Consumer<OnboardingProvider>(builder: (context, provider, _) {
        final onboardingPages = provider.getOnboardingPages();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('FarmAgent'),
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
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: onboardingPages.length,
                      onPageChanged: (index) {
                        provider.setCurrentIndex(index);
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
                                    onboardingPages[index].image,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  onboardingPages[index].title,
                                  style: AppFonts.text20normal(
                                    context,
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  onboardingPages[index].subdescription,
                                  textAlign: TextAlign.center,
                                  style: AppFonts.text12normal(
                                    context,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ],
                            )
                          ],
                        );
                      },
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            _onNext(provider, onboardingPages.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                        ),
                        child: Text(
                          provider.currentIndex == onboardingPages.length - 1
                              ? 'Finish'
                              : 'Next',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border: Border.all(
                            color: AppColors.borderDivider,
                            width: 2,
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: TextButton(
                          onPressed: _onSkip,
                          child: Text(
                            'Skip',
                            style: TextStyle(color: AppColors.primaryGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
