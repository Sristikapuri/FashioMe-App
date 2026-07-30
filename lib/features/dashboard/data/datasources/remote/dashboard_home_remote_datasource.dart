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

  String _occasionFallbackImage(String occasion) {
    final value = occasion.toLowerCase();
    if (value.contains('wedding') || value.contains('gala') || value.contains('black tie')) {
      return 'assets/images/ai_wedding_formal.jpg';
    }
    if (value.contains('party') || value.contains('festival') || value.contains('sangeet')) {
      return 'assets/images/party.jpg';
    }
    if (value.contains('office') || value.contains('work')) {
      return 'assets/images/outfit.jpg';
    }
    if (value.contains('brunch') || value.contains('date')) {
      return 'assets/images/brunch.jpg';
    }
    if (value.contains('travel') || value.contains('beach')) {
      return 'assets/images/travel.jpg';
    }
    if (value.contains('winter') || value.contains('monsoon')) {
      return 'assets/images/weekend.jpg';
    }
    return 'assets/images/outfit.jpg';
  }

  List<DiscoverEntry> _parseDiscoverEntries(dynamic data) {
    final payload = data is Map ? data['responseData'] : null;
    if (payload is List) {
      const fallbackImages = [
        'assets/images/outfit.jpg',
        'assets/images/ai_wedding_formal.jpg',
        'assets/images/wedding.jpg',
        'assets/images/party.jpg',
        'assets/images/brunch.jpg',
        'assets/images/travel.jpg',
      ];
      return payload
          .whereType<Map>()
          .toList()
          .asMap()
          .entries
          .map((entry) {
            final json = Map<String, dynamic>.from(entry.value);
            final imageUrl = (json['imageUrl'] ?? '').toString().trim();
            if (imageUrl.isEmpty) {
              json['imageUrl'] = fallbackImages[entry.key % fallbackImages.length];
            }
            return DiscoverEntry.fromJson(json);
          })
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
      final json = Map<String, dynamic>.from(payload);
      if ((json['imageUrl'] ?? '').toString().trim().isEmpty) {
        json['imageUrl'] = _occasionFallbackImage(occasion);
      }
      return DashboardRecommendation.fromJson(json);
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
