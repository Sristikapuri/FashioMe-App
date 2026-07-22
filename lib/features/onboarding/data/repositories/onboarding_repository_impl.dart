import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/onboarding/data/datasources/local/onboarding_local_datasource.dart';
import 'package:fashio_me/features/onboarding/data/datasources/onboarding_datasource.dart';
import 'package:fashio_me/features/onboarding/data/datasources/remote/onboarding_remote_datasource.dart';
import 'package:fashio_me/features/onboarding/domain/entities/onboarding_item.dart';
import 'package:fashio_me/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<IOnboardingRepository>((ref) {
  final remoteDataSource = ref.read(onboardingRemoteDataSourceProvider);
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
  }) : _remoteDataSource = remoteDataSource,
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
      // The first-run screen can be shown before authentication. Keep the
      // local completion marker even when the protected API is unavailable.
      try {
        await _remoteDataSource.completeOnboarding();
      } catch (_) {
        // Sync will be retried by the next authenticated flow.
      }
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
      final localCompleted = await _localDataSource.hasCompletedOnboarding();
      if (localCompleted) return Right(localCompleted);

      // Fall back to remote
      try {
        return Right(await _remoteDataSource.hasCompletedOnboarding());
      } catch (_) {
        return const Right(false);
      }
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}
