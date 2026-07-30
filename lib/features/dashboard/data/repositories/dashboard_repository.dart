import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_repository.dart';
class DashboardRepository implements IDashboardRepository {
  final IDashboardDataSource _remoteDataSource;
  final IDashboardDataSource _localDataSource;

  DashboardRepository({
    required IDashboardDataSource remoteDataSource,
    required IDashboardDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Either<Failure, DashboardEntity>> getDashboardData() async {
    try {
      try {
        final dashboardModel = await _remoteDataSource.getDashboardData();
        return Right(dashboardModel.toEntity());
      } catch (_) {
        final dashboardModel = await _localDataSource.getDashboardData();
        return Right(dashboardModel.toEntity());
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}
