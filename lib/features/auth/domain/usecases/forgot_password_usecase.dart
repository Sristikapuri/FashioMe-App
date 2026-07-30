import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUsecase {
  const ForgotPasswordUsecase(this._repository);
  final IAuthRepository _repository;

  Future<Either<Failure, bool>> call(String email) =>
      _repository.forgotPassword(email);
}
