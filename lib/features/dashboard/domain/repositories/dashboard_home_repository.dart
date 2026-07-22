import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entities.dart';

abstract interface class IDashboardHomeRepository {
  Future<DashboardRecommendation> generateOutfit({
    required String occasion,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
    String source = 'My Wardrobe',
    String? imageReference,
  });

  Future<List<DiscoverEntry>> fetchTrends();

  Future<Map<String, dynamic>> search({
    required String query,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
  });

  Future<Map<String, dynamic>> chatWithAssistant({
    required String message,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
    required String source,
    DashboardRecommendation? currentRecommendation,
  });

  Future<Map<String, dynamic>> generateProfile({
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
    required String imageReference,
    required String occasion,
    required String source,
  });

  Future<List<WardrobeEntry>> fetchWardrobe();

  Future<void> syncWardrobe(List<WardrobeEntry> items);

  Future<void> createWardrobeItem(WardrobeEntry item);

  Future<void> updateWardrobeItem(WardrobeEntry item);

  Future<void> deleteWardrobeItem(String itemId);
}
