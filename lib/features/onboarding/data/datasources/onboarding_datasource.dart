import 'package:fashio_me/features/onboarding/data/models/onboarding_item_model.dart';

abstract interface class IOnboardingDataSource {
  List<OnboardingItemModel> getOnboardingItems();
  Future<void> completeOnboarding();
  Future<bool> hasCompletedOnboarding();
}
