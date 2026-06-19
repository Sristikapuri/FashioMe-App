import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/silhouette/data/repositories/silhouette_repository_impl.dart'
    as silhouette_repo;
import 'package:fashio_me/features/silhouette/domain/repositories/silhouette_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hasCompletedSilhouetteProfileUsecaseProvider =
    Provider<HasCompletedSilhouetteProfileUsecase>((ref) {
  return HasCompletedSilhouetteProfileUsecase(
    silhouetteRepository: ref.read(silhouette_repo.silhouetteRepositoryProvider),
  );
});

class HasCompletedSilhouetteProfileUsecase
    implements UsecaseWithoutParams<bool> {
  HasCompletedSilhouetteProfileUsecase({
    required ISilhouetteRepository silhouetteRepository,
  }) : _silhouetteRepository = silhouetteRepository;

  final ISilhouetteRepository _silhouetteRepository;

  @override
  Future<Either<Failure, bool>> call() {
    return _silhouetteRepository.hasCompletedProfile();
  }
}

