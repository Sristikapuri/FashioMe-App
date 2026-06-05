import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/onboarding/data/datasources/local/onboarding_local_datasource.dart';
import 'package:fashio_me/features/onboarding/data/datasources/onboarding_datasource.dart';
import 'package:fashio_me/features/onboarding/data/datasources/remote/onboarding_remote_datasource.dart';
import 'package:fashio_me/features/onboarding/domain/entities/onboarding_item.dart';
import 'package:fashio_me/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<IOnboardingRepository>((ref) {
  final remoteDataSource = OnboardingRemoteDataSource();
  final localDataSource = ref.read(onboardingLocalDataSourceProvider);
  return OnboardingRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

class OnboardingRepositoryImpl implements IOnboardingRepository {
  final IOnboardingDataSource _remoteDataSource;
  final IOnboardingDataSource _localDataSource;

  OnboardingRepositoryImpl({
    required IOnboardingDataSource remoteDataSource,
    required IOnboardingDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<OnboardingItem>>> getOnboardingItems() async {
    try {
      // Try remote first, fall back to local
      try {
        final items = _remoteDataSource.getOnboardingItems();
        return Right(items.map((e) => e.toEntity()).toList());
      } catch (e) {
        final items = _localDataSource.getOnboardingItems();
        return Right(items.map((e) => e.toEntity()).toList());
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> completeOnboarding() async {
    try {
      await _remoteDataSource.completeOnboarding();
      await _localDataSource.completeOnboarding();
      return const Right(true);
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
