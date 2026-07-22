import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';
import 'package:fashio_me/features/silhouette/domain/repositories/silhouette_repository.dart';

class SaveSilhouetteProfileUsecase
    implements UsecaseWithParams<bool, SaveSilhouetteProfileParams> {
  SaveSilhouetteProfileUsecase({
    required ISilhouetteRepository silhouetteRepository,
  }) : _silhouetteRepository = silhouetteRepository;

  final ISilhouetteRepository _silhouetteRepository;

  @override
  Future<Either<Failure, bool>> call(SaveSilhouetteProfileParams params) {
    return _silhouetteRepository.saveProfile(params.profile);
  }
}

class SaveSilhouetteProfileParams {
  const SaveSilhouetteProfileParams({required this.profile});

  final SilhouetteProfile profile;
}
