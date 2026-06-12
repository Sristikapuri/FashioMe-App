import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/auth/data/repositories/auth_repository.dart'
    as auth_repo;
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isLoggedInUsecaseProvider = Provider<IsLoggedInUsecase>((ref) {
  return IsLoggedInUsecase(
    authRepository: ref.read(auth_repo.authRepositoryProvider),
  );
});

class IsLoggedInUsecase implements UsecaseWithoutParams<bool> {
  IsLoggedInUsecase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  final IAuthRepository _authRepository;

  @override
  Future<Either<Failure, bool>> call() {
    return _authRepository.isLoggedIn();
  }
}
