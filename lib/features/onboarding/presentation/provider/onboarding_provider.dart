import 'package:flutter/material.dart';
import '../../data/onboarding_model_impl.dart';
import '../../data/models/onboarding_model.dart';

class OnboardingProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  // Method to get onboarding pages from OnboardingModelImpl
  List<OnboardingModel> getOnboardingPages() {
    return OnboardingModelImpl().onboard;
  }

  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void nextPage(int totalPages) {
    if (_currentIndex < totalPages - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }
}
