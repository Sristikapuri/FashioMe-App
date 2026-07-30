import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';

class ResetPasswordUsecase {
  const ResetPasswordUsecase(this._repository);
  final IAuthRepository _repository;

  Future<Either<Failure, bool>> call({required String email, required String token, required String password}) =>
      _repository.resetPassword(email: email, token: token, password: password);
}
