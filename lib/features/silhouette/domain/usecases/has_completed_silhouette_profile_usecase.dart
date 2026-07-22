import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/repositories/silhouette_repository.dart';

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
