import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/silhouette/data/repositories/silhouette_repository_impl.dart'
    as silhouette_repo;
import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';
import 'package:fashio_me/features/silhouette/domain/repositories/silhouette_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getSilhouetteProfileUsecaseProvider = Provider<GetSilhouetteProfileUsecase>((ref) {
  return GetSilhouetteProfileUsecase(
    silhouetteRepository: ref.read(silhouette_repo.silhouetteRepositoryProvider),
  );
});

class GetSilhouetteProfileUsecase
    implements UsecaseWithoutParams<SilhouetteProfile?> {
  GetSilhouetteProfileUsecase({required ISilhouetteRepository silhouetteRepository})
      : _silhouetteRepository = silhouetteRepository;

  final ISilhouetteRepository _silhouetteRepository;

  @override
  Future<Either<Failure, SilhouetteProfile?>> call() {
    return _silhouetteRepository.getProfile();
  }
}

