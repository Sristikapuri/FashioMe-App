import 'package:fashio_me/core/providers/storage_provider.dart';
import 'package:fashio_me/core/services/storage/storage_service.dart';
import 'package:fashio_me/features/onboarding/data/datasources/onboarding_datasource.dart';
import 'package:fashio_me/features/onboarding/data/models/onboarding_item_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingLocalDataSourceProvider = Provider<IOnboardingDataSource>((
  ref,
) {
  final storageService = ref.read(storageServiceProvider);
  return OnboardingLocalDataSource(storageService: storageService);
});

class OnboardingLocalDataSource implements IOnboardingDataSource {
  final StorageService _storageService;

  OnboardingLocalDataSource({required StorageService storageService})
    : _storageService = storageService;

  @override
  List<OnboardingItemModel> getOnboardingItems() {
    return [
      OnboardingItemModel(
        title: 'Your AI Stylist,\nReimagined.',
        subtitle:
            'Merging the heritage of the Saree with the edge of modern tailoring.',
        imageUrl:
            'https://images.unsplash.com/photo-1496747611176-843222e1e57c',
      ),
      OnboardingItemModel(
        title: 'Luxury Meets\nTechnology.',
        subtitle:
            'Discover premium fashion recommendations powered by AI intelligence.',
        imageUrl:
            'https://images.unsplash.com/photo-1529139574466-a303027c1d8b',
      ),
      OnboardingItemModel(
        title: 'Create Your\nOwn Identity.',
        subtitle: 'Fashion curated uniquely for your personality and culture.',
        imageUrl:
            'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f',
      ),
    ];
  }

  @override
  Future<void> completeOnboarding() async {
    await _storageService.setBool('onboarding_completed', true);
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    return _storageService.getBool('onboarding_completed') ?? false;
  }
}
