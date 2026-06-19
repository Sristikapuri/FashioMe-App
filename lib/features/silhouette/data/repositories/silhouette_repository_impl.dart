import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/silhouette/data/datasources/local/silhouette_local_datasource.dart';
import 'package:fashio_me/features/silhouette/data/datasources/silhouette_datasource.dart';
import 'package:fashio_me/features/silhouette/data/models/silhouette_profile_model.dart';
import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';
import 'package:fashio_me/features/silhouette/domain/repositories/silhouette_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final silhouetteRepositoryProvider = Provider<ISilhouetteRepository>((ref) {
  return SilhouetteRepositoryImpl(
    localDataSource: ref.read(silhouetteLocalDataSourceProvider),
  );
});

class SilhouetteRepositoryImpl implements ISilhouetteRepository {
  SilhouetteRepositoryImpl({required ISilhouetteDataSource localDataSource})
    : _localDataSource = localDataSource;

  final ISilhouetteDataSource _localDataSource;

  @override
  Future<Either<Failure, SilhouetteProfile?>> getProfile() async {
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
    try {
      final model = SilhouetteProfileModel.fromEntity(profile);
      await _localDataSource.saveProfile(model);
      return const Right(true);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> clearProfile() async {
    try {
      await _localDataSource.clearProfile();
      return const Right(true);
    } catch (e) {
      return Left(LocalDatabaseFailure(message: e.toString()));
    }
  }
}

