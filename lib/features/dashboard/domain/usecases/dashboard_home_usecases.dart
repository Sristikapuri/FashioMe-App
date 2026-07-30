import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_home_repository.dart';

class DashboardHomeUsecases {
  const DashboardHomeUsecases(this._repository);
  final IDashboardHomeRepository _repository;

  Future<DashboardRecommendation> generateOutfit({required String occasion, required DashboardProfileData profileData, required Map<String, int> preferenceScores, String source = 'My Wardrobe', String? imageReference}) => _repository.generateOutfit(occasion: occasion, profileData: profileData, preferenceScores: preferenceScores, source: source, imageReference: imageReference);
  Future<List<DiscoverEntry>> fetchTrends() => _repository.fetchTrends();
  Future<Map<String, dynamic>> search({required String query, required DashboardProfileData profileData, required Map<String, int> preferenceScores}) => _repository.search(query: query, profileData: profileData, preferenceScores: preferenceScores);
  Future<Map<String, dynamic>> chatWithAssistant({required String message, required DashboardProfileData profileData, required Map<String, int> preferenceScores, required String source, DashboardRecommendation? currentRecommendation}) => _repository.chatWithAssistant(message: message, profileData: profileData, preferenceScores: preferenceScores, source: source, currentRecommendation: currentRecommendation);
  Future<Map<String, dynamic>> generateProfile({required DashboardProfileData profileData, required Map<String, int> preferenceScores, required String imageReference, required String occasion, required String source}) => _repository.generateProfile(profileData: profileData, preferenceScores: preferenceScores, imageReference: imageReference, occasion: occasion, source: source);
  Future<List<WardrobeEntry>> fetchWardrobe() => _repository.fetchWardrobe();
  Future<void> syncWardrobe(List<WardrobeEntry> items) => _repository.syncWardrobe(items);
  Future<void> createWardrobeItem(WardrobeEntry item) => _repository.createWardrobeItem(item);
  Future<void> updateWardrobeItem(WardrobeEntry item) => _repository.updateWardrobeItem(item);
  Future<void> deleteWardrobeItem(String id) => _repository.deleteWardrobeItem(id);
}
