import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/dashboard/data/datasources/local/dashboard_state_local_datasource.dart';
import 'package:fashio_me/features/dashboard/data/datasources/dashboard_state_datasource.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_state_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardStateRepositoryProvider = Provider<IDashboardStateRepository>((ref) {
  return DashboardStateRepositoryImpl(
    localDataSource: ref.read(dashboardStateLocalDataSourceProvider),
  );
});

class DashboardStateRepositoryImpl implements IDashboardStateRepository {
  DashboardStateRepositoryImpl({required IDashboardStateDataSource localDataSource})
      : _localDataSource = localDataSource;

  final IDashboardStateDataSource _localDataSource;

  @override
  Future<Either<Failure, Map<String, dynamic>>> read() async {
    try {
      return Right(_localDataSource.read());
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> write(Map<String, dynamic> payload) async {
    try {
      await _localDataSource.write(payload);
      return const Right(true);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}

