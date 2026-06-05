import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:fashio_me/features/dashboard/data/datasources/local/dashboard_local_datasource.dart';
import 'package:fashio_me/features/dashboard/data/datasources/remote/dashboard_remote_datasource.dart';
import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entity.dart';
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

class DashboardRepositoryImpl implements IDashboardRepository {
  final IDashboardDataSource _remoteDataSource;
  final IDashboardDataSource _localDataSource;

  DashboardRepositoryImpl({
    required IDashboardDataSource remoteDataSource,
    required IDashboardDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, DashboardEntity>> getDashboardData() async {
    try {
      // Try remote first, fall back to local
      try {
        final dashboardModel = _remoteDataSource.getDashboardData();
        return Right(dashboardModel.toEntity());
      } catch (e) {
        final dashboardModel = _localDataSource.getDashboardData();
        return Right(dashboardModel.toEntity());
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}
