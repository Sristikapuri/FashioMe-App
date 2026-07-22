import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardHomeRemoteDataSourceProvider =
    Provider<DashboardHomeRemoteDataSource>((ref) {
      return DashboardHomeRemoteDataSource(
        apiClient: ref.read(apiClientProvider),
      );
    });

class DashboardHomeRemoteDataSource {
  DashboardHomeRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  List<DiscoverEntry> _parseDiscoverEntries(dynamic data) {
    final payload = data is Map ? data['responseData'] : null;
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map(
            (item) => DiscoverEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    }
    throw StateError('Unexpected trends response.');
  }

  List<WardrobeEntry> _parseWardrobeEntries(dynamic data) {
    final payload = data is Map ? data['responseData'] : null;
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map(
            (item) => WardrobeEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    }
    throw StateError('Unexpected wardrobe response.');
  }

  Future<DashboardRecommendation> generateOutfit({
    required String occasion,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
    String source = 'My Wardrobe',
    String? imageReference,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.homeGenerateOutfit,
      data: {
        'occasion': occasion,
        'source': source,
        'profileData': profileData.toJson(),
        'preferenceScores': preferenceScores,
        if (imageReference != null && imageReference.isNotEmpty)
          'imageReference': imageReference,
      },
    );

    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    if (payload is Map) {
      return DashboardRecommendation.fromJson(
        Map<String, dynamic>.from(payload),
      );
    }
    throw StateError('Unexpected generate outfit response.');
  }

  Future<List<DiscoverEntry>> fetchTrends() async {
    final response = await _apiClient.get(ApiEndpoints.homeTrends);
    return _parseDiscoverEntries(response.data);
  }

  Future<Map<String, dynamic>> search({
    required String query,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.homeSearch,
      data: {
        'query': query,
        'profileData': profileData.toJson(),
        'preferenceScores': preferenceScores,
      },
    );

    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw StateError('Unexpected search response.');
  }

  Future<Map<String, dynamic>> chatWithAssistant({
    required String message,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
    required String source,
    DashboardRecommendation? currentRecommendation,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.homeAssistantChat,
      data: {
        'message': message,
        'profileData': profileData.toJson(),
        'preferenceScores': preferenceScores,
        'source': source,
        if (currentRecommendation != null)
          'currentRecommendation': currentRecommendation.toJson(),
      },
    );

    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw StateError('Unexpected assistant response.');
  }

  Future<Map<String, dynamic>> generateProfile({
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
    required String imageReference,
    required String occasion,
    required String source,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.homeGenerateProfile,
      data: {
        'profileData': profileData.toJson(),
        'preferenceScores': preferenceScores,
        'imageReference': imageReference,
        'occasion': occasion,
        'source': source,
      },
    );

    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }
    throw StateError('Unexpected profile generation response.');
  }

  Future<List<WardrobeEntry>> fetchWardrobe() async {
    final response = await _apiClient.get(ApiEndpoints.homeWardrobe);
    return _parseWardrobeEntries(response.data);
  }

  Future<void> syncWardrobe(List<WardrobeEntry> items) async {
    await _apiClient.post(
      ApiEndpoints.homeWardrobeSync,
      data: {'items': items.map((item) => item.toJson()).toList()},
    );
  }

  Future<void> createWardrobeItem(WardrobeEntry item) async {
    await _apiClient.post(ApiEndpoints.homeWardrobe, data: item.toJson());
  }

  Future<void> updateWardrobeItem(WardrobeEntry item) async {
    await _apiClient.patch(
      ApiEndpoints.homeWardrobeItem(item.id),
      data: item.toJson(),
    );
  }

  Future<void> deleteWardrobeItem(String itemId) async {
    await _apiClient.delete(ApiEndpoints.homeWardrobeItem(itemId));
  }
}
