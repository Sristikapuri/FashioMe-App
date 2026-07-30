import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/features/style_archive/data/models/style_archive_entry_model.dart';

final styleArchiveRemoteDataSourceProvider =
    Provider<StyleArchiveRemoteDataSource>((ref) {
      return StyleArchiveRemoteDataSource(
        apiClient: ref.read(apiClientProvider),
      );
    });

class StyleArchiveRemoteDataSource {
  StyleArchiveRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  List<StyleArchiveEntryModel> _parseArchive(dynamic data) {
    final payload = data is Map ? data['responseData'] : null;
    final archive = payload is Map ? payload['styleArchive'] : null;
    if (archive is! List) {
      return const [];
    }
    return archive
        .whereType<Map>()
        .map(
          (item) =>
              StyleArchiveEntryModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<List<StyleArchiveEntryModel>> fetchStyleArchive() async {
    final response = await _apiClient.get(ApiEndpoints.userStyleArchive);
    return _parseArchive(response.data);
  }

  Future<List<StyleArchiveEntryModel>> saveStyleArchiveEntry({
    required String weekKey,
    required String day,
    required String occasion,
    String title = '',
    String outfit = '',
    String imageUrl = '',
    String explanation = '',
    List<String> paletteLabels = const [],
    List<String> wardrobeItemsUsed = const [],
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.userStyleArchive,
      data: {
        'weekKey': weekKey,
        'day': day,
        'occasion': occasion,
        'title': title,
        'outfit': outfit,
        'imageUrl': imageUrl,
        'explanation': explanation,
        'paletteLabels': paletteLabels,
        'wardrobeItemsUsed': wardrobeItemsUsed,
      },
    );
    return _parseArchive(response.data);
  }
}
