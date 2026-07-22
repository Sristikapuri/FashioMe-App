import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';

class GetInitialRouteUsecase implements UsecaseWithoutParams<String> {
  GetInitialRouteUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  final IAuthRepository _authRepository;

  @override
  Future<Either<Failure, String>> call() {
    return _authRepository.getInitialRoute();
  }
}
