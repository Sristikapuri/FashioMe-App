import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';

abstract interface class ISilhouetteRepository {
  Future<Either<Failure, SilhouetteProfile?>> getProfile();
  Future<Either<Failure, bool>> hasCompletedProfile();
  Future<Either<Failure, bool>> saveProfile(SilhouetteProfile profile);
  Future<Either<Failure, bool>> clearProfile();
}

