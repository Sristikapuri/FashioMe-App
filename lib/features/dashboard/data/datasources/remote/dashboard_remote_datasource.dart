import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:fashio_me/features/dashboard/data/models/dashboard_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardRemoteDataSourceProvider = Provider<IDashboardDataSource>((ref) {
  return DashboardRemoteDataSource(apiClient: ref.read(apiClientProvider));
});

class DashboardRemoteDataSource implements IDashboardDataSource {
  DashboardRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<DashboardModel> getDashboardData() async {
    final response = await _apiClient.get(ApiEndpoints.homeDashboard);
    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    if (payload is Map) {
      return DashboardModel.fromJson(Map<String, dynamic>.from(payload));
    }
    throw StateError('Unexpected dashboard response.');
  }
}
