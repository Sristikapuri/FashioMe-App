import 'package:fashio_me/features/dashboard/data/models/dashboard_model.dart';

abstract interface class IDashboardDataSource {
  Future<DashboardModel> getDashboardData();
}
