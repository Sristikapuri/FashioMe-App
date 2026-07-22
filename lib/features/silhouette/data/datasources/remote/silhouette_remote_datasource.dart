import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/features/silhouette/data/models/silhouette_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final silhouetteRemoteDataSourceProvider = Provider<SilhouetteRemoteDataSource>(
  (ref) {
    return SilhouetteRemoteDataSource(apiClient: ref.read(apiClientProvider));
  },
);

class SilhouetteRemoteDataSource {
  SilhouetteRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Fetch the user's silhouette profile from the backend.
  Future<SilhouetteProfileModel?> fetchProfile() async {
    final response = await _apiClient.get(ApiEndpoints.silhouetteProfile);
    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    if (payload is Map<String, dynamic>) {
      return SilhouetteProfileModel.fromBackendJson(payload);
    }
    return null;
  }

  /// Save / upsert the silhouette profile to the backend.
  /// Sends field names that match the MongoDB schema.
  Future<SilhouetteProfileModel> saveProfile(
    SilhouetteProfileModel profile,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.silhouetteProfile,
      data: profile.toBackendJson(),
    );
    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    if (payload is Map<String, dynamic>) {
      return SilhouetteProfileModel.fromBackendJson(payload);
    }
    // Return the same profile if the response payload is unexpected
    return profile;
  }

  /// Clear the silhouette profile on the backend.
  Future<void> clearProfile() async {
    await _apiClient.delete(ApiEndpoints.silhouetteProfile);
  }
}
