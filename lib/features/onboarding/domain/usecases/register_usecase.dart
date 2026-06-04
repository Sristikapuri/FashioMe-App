import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return RegisterUsecase(authRepository: authRepository);
});

class RegisterUsecaseParams extends Equatable {
  final String fullName;
  final String email;
  final String password;

  const RegisterUsecaseParams({
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [fullName, email, password];
}

class RegisterUsecase
    implements UsecaseWithParams<AuthEntity, RegisterUsecaseParams> {
  RegisterUsecase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  final IAuthRepository _authRepository;

  @override
  Future<Either<Failure, AuthEntity>> call(RegisterUsecaseParams params) {
    return _authRepository.register(
      AuthEntity(
        fullName: params.fullName,
        email: params.email,
        password: params.password,
      ),
    );
  }
}
