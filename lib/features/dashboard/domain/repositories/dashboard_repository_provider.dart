import 'package:fashio_me/features/dashboard/data/datasources/local/dashboard_local_datasource.dart';
import 'package:fashio_me/features/dashboard/data/datasources/remote/dashboard_remote_datasource.dart';
import 'package:fashio_me/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardRepositoryProvider = Provider<IDashboardRepository>((ref) {
  final remoteDataSource = DashboardRemoteDataSource();
  final localDataSource = DashboardLocalDataSource();
  return DashboardRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});
