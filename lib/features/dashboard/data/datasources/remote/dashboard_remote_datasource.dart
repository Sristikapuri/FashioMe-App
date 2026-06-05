import 'package:fashio_me/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:fashio_me/features/dashboard/data/models/dashboard_model.dart';

class DashboardRemoteDataSource implements IDashboardDataSource {
  @override
  DashboardModel getDashboardData() {
    // In a real app, this would fetch from an API
    return DashboardModel.fromMockData();
  }
}
