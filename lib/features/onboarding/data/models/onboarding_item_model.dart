import 'package:fashio_me/features/onboarding/domain/entities/onboarding_item.dart';

class OnboardingItemModel {
  final String title;
  final String subtitle;
  final String imageUrl;

  OnboardingItemModel({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  OnboardingItem toEntity() {
    return OnboardingItem(
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
    );
  }

  factory OnboardingItemModel.fromEntity(OnboardingItem entity) {
    return OnboardingItemModel(
      title: entity.title,
      subtitle: entity.subtitle,
      imageUrl: entity.imageUrl,
    );
  }
}
