import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/silhouette/data/datasources/local/silhouette_local_datasource.dart';
import 'package:fashio_me/features/silhouette/data/datasources/remote/silhouette_remote_datasource.dart';
import 'package:fashio_me/features/silhouette/data/datasources/silhouette_datasource.dart';
import 'package:fashio_me/features/silhouette/data/models/silhouette_profile_model.dart';
import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';
import 'package:fashio_me/features/silhouette/domain/repositories/silhouette_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final silhouetteRepositoryProvider = Provider<ISilhouetteRepository>((ref) {
  return SilhouetteRepositoryImpl(
    localDataSource: ref.read(silhouetteLocalDataSourceProvider),
    remoteDataSource: ref.read(silhouetteRemoteDataSourceProvider),
  );
});

class SilhouetteRepositoryImpl implements ISilhouetteRepository {
  SilhouetteRepositoryImpl({
    required ISilhouetteDataSource localDataSource,
    required SilhouetteRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final ISilhouetteDataSource _localDataSource;
  final SilhouetteRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, SilhouetteProfile?>> getProfile() async {
    // 1. Try fetching from the backend first (source of truth)
    try {
      final remote = await _remoteDataSource.fetchProfile();
      if (remote != null) {
        // Cache the backend value locally so the app works offline
        await _localDataSource.saveProfile(remote);
        return Right(remote.toEntity());
      }
    } catch (e) {
      debugPrint('[Silhouette] Remote fetch failed, falling back to local: $e');
    }

    // 2. Fall back to locally cached value
    try {
      final model = _localDataSource.getProfile();
      return Right(model?.toEntity());
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasCompletedProfile() async {
    try {
      return Right(_localDataSource.hasCompletedProfile());
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> saveProfile(SilhouetteProfile profile) async {
    final model = SilhouetteProfileModel.fromEntity(profile);

    // 1. Persist to backend (source of truth)
    try {
      final saved = await _remoteDataSource.saveProfile(model);
      // 2. Cache the confirmed backend response locally
      await _localDataSource.saveProfile(saved);
      return const Right(true);
    } catch (remoteError) {
      debugPrint(
        '[Silhouette] Backend save failed, saving locally only: $remoteError',
      );
      // 3. Fallback: save locally so the user doesn't lose data
      try {
        await _localDataSource.saveProfile(model);
        // Return false to signal partial success (local only)
        return const Right(false);
      } catch (localError) {
        return Left(LocalDatabaseFailure(message: localError.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> clearProfile() async {
    try {
      await _remoteDataSource.clearProfile();
    } catch (e) {
      debugPrint('[Silhouette] Remote clear failed: $e');
    }
    try {
      await _localDataSource.clearProfile();
      return const Right(true);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}
