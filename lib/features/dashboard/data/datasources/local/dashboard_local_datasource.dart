import 'package:fashio_me/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:fashio_me/features/dashboard/data/models/dashboard_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardLocalDataSourceProvider = Provider<IDashboardDataSource>((ref) {
  return DashboardLocalDataSource();
});

class DashboardLocalDataSource implements IDashboardDataSource {
  @override
  DashboardModel getDashboardData() {
    // In a real app, this would fetch from local database/cache
    return DashboardModel.fromMockData();
  }
}
