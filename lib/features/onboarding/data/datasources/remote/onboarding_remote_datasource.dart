import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/features/onboarding/data/datasources/onboarding_datasource.dart';
import 'package:fashio_me/features/onboarding/data/models/onboarding_item_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRemoteDataSourceProvider = Provider<OnboardingRemoteDataSource>(
  (ref) => OnboardingRemoteDataSource(apiClient: ref.read(apiClientProvider)),
);

class OnboardingRemoteDataSource implements IOnboardingDataSource {
  OnboardingRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  List<OnboardingItemModel> getOnboardingItems() {
    // In a real app, this would fetch from an API
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
    final response = await _apiClient.post(ApiEndpoints.onboardingComplete);
    final data = response.data;
    if (data is Map && data['isSuccess'] == false) {
      throw StateError(
        (data['responseMessage'] ?? 'Unable to complete onboarding').toString(),
      );
    }
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final response = await _apiClient.get(ApiEndpoints.onboardingStatus);
    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    return payload is Map && payload['completed'] == true;
  }
}
