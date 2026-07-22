import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';

class DeleteAccountUsecase implements UsecaseWithoutParams<bool> {
  DeleteAccountUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  final IAuthRepository _authRepository;

  @override
  Future<Either<Failure, bool>> call() => _authRepository.deleteAccount();
}
