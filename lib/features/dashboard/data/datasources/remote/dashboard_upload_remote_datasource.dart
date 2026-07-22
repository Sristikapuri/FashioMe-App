import 'package:dio/dio.dart';
import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/features/dashboard/data/datasources/dashboard_upload_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardUploadRemoteDataSourceProvider =
    Provider<IDashboardUploadDataSource>((ref) {
      return DashboardUploadRemoteDataSource(
        apiClient: ref.read(apiClientProvider),
      );
    });

class DashboardUploadRemoteDataSource implements IDashboardUploadDataSource {
  DashboardUploadRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Response<dynamic>> uploadItemPhoto({
    required String imagePath,
    required String fileName,
    void Function(int sentBytes, int totalBytes)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath, filename: fileName),
    });
    return _apiClient.uploadFile(
      ApiEndpoints.itemUploadPhoto,
      formData: formData,
      onSendProgress: onSendProgress,
    );
  }
}
