import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/splash/data/datasources/local/splash_local_datasource.dart';
import 'package:fashio_me/features/splash/data/datasources/remote/splash_remote_datasource.dart';
import 'package:fashio_me/features/splash/data/datasources/splash_datasource.dart';
import 'package:fashio_me/features/splash/domain/repositories/splash_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashRepositoryProvider = Provider<ISplashRepository>((ref) {
  final remoteDataSource = SplashRemoteDataSource();
  final localDataSource = ref.read(splashLocalDataSourceProvider);
  return SplashRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

class SplashRepositoryImpl implements ISplashRepository {
  final ISplashDataSource _remoteDataSource;
  final ISplashDataSource _localDataSource;

  SplashRepositoryImpl({
    required ISplashDataSource remoteDataSource,
    required ISplashDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      // Check local first
      final localLoggedIn = _localDataSource.isLoggedIn();
      if (localLoggedIn) return Right(localLoggedIn);

      // Fall back to remote
      return Right(_remoteDataSource.isLoggedIn());
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasCompletedOnboarding() async {
    try {
      // Check local first
      final localCompleted = _localDataSource.hasCompletedOnboarding();
      if (localCompleted) return Right(localCompleted);

      // Fall back to remote
      return Right(_remoteDataSource.hasCompletedOnboarding());
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}
