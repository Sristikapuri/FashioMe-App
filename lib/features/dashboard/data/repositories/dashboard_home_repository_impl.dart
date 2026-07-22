import 'package:fashio_me/features/dashboard/data/datasources/remote/dashboard_home_remote_datasource.dart';
import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_home_repository.dart';

class DashboardHomeRepositoryImpl implements IDashboardHomeRepository {
  DashboardHomeRepositoryImpl({
    required DashboardHomeRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final DashboardHomeRemoteDataSource _remoteDataSource;

  @override
  Future<Map<String, dynamic>> chatWithAssistant({
    required String message,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
    required String source,
    DashboardRecommendation? currentRecommendation,
  }) {
    return _remoteDataSource.chatWithAssistant(
      message: message,
      profileData: profileData,
      preferenceScores: preferenceScores,
      source: source,
      currentRecommendation: currentRecommendation,
    );
  }

  @override
  Future<void> createWardrobeItem(WardrobeEntry item) {
    return _remoteDataSource.createWardrobeItem(item);
  }

  @override
  Future<void> deleteWardrobeItem(String itemId) {
    return _remoteDataSource.deleteWardrobeItem(itemId);
  }

  @override
  Future<List<WardrobeEntry>> fetchWardrobe() {
    return _remoteDataSource.fetchWardrobe();
  }

  @override
  Future<List<DiscoverEntry>> fetchTrends() {
    return _remoteDataSource.fetchTrends();
  }

  @override
  Future<DashboardRecommendation> generateOutfit({
    required String occasion,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
    String source = 'My Wardrobe',
    String? imageReference,
  }) {
    return _remoteDataSource.generateOutfit(
      occasion: occasion,
      profileData: profileData,
      preferenceScores: preferenceScores,
      source: source,
      imageReference: imageReference,
    );
  }

  @override
  Future<Map<String, dynamic>> generateProfile({
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
    required String imageReference,
    required String occasion,
    required String source,
  }) {
    return _remoteDataSource.generateProfile(
      profileData: profileData,
      preferenceScores: preferenceScores,
      imageReference: imageReference,
      occasion: occasion,
      source: source,
    );
  }

  @override
  Future<Map<String, dynamic>> search({
    required String query,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
  }) {
    return _remoteDataSource.search(
      query: query,
      profileData: profileData,
      preferenceScores: preferenceScores,
    );
  }

  @override
  Future<void> syncWardrobe(List<WardrobeEntry> items) {
    return _remoteDataSource.syncWardrobe(items);
  }

  @override
  Future<void> updateWardrobeItem(WardrobeEntry item) {
    return _remoteDataSource.updateWardrobeItem(item);
  }
}
