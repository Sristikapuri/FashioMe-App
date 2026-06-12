import 'package:fashio_me/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:fashio_me/features/dashboard/data/models/dashboard_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardRemoteDataSourceProvider = Provider<IDashboardDataSource>((ref) {
  return DashboardRemoteDataSource();
});

class DashboardRemoteDataSource implements IDashboardDataSource {
  @override
  DashboardModel getDashboardData() {
    // In a real app, this would fetch from an API
    return DashboardModel.fromMockData();
  }
}
