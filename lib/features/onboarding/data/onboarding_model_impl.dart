import 'package:smart_farm/core/constants/app_string.dart';
import 'package:smart_farm/features/onboarding/data/models/onboarding_model.dart';

class OnboardingModelImpl {
  late OnboardingModel onboardingModel;

  final List<OnboardingModel> onboard = [
    OnboardingModel(
      title: AppString.onboardingTitle1,
      description: AppString.onboardingDescriprtion1,
      subdescription: AppString.onboardingSubDescription1,
      image: AppString.onboardingImage1,
    ),
    OnboardingModel(
      title: AppString.onboardingTitle2,
      description: AppString.onboardingDescriprtion2,
      subdescription: AppString.onboardingSubDescription2,
      image: AppString.onboardingImage2,
    ),
    OnboardingModel(
      title: AppString.onboardingTitle3,
      description: AppString.onboardingDescriprtion3,
      subdescription: AppString.onboardingSubDescription2,
      image: AppString.onboardingImage3,
    ),
  ];
}
