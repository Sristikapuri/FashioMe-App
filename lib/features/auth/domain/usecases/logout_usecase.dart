import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/auth/data/repositories/auth_repository.dart'
    as auth_repo;
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  return LogoutUsecase(authRepository: ref.read(auth_repo.authRepositoryProvider));
});

class LogoutUsecaseParams extends Equatable {
  const LogoutUsecaseParams();

  @override
  List<Object?> get props => [];
}

class LogoutUsecase implements UsecaseWithParams<bool, LogoutUsecaseParams> {
  LogoutUsecase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  final IAuthRepository _authRepository;

  @override
  Future<Either<Failure, bool>> call(LogoutUsecaseParams params) {
    return _authRepository.logout();
  }
}
