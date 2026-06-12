import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/auth/data/repositories/auth_repository.dart'
    as auth_repo;
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  return RegisterUsecase(
    authRepository: ref.read(auth_repo.authRepositoryProvider),
  );
});

class RegisterUsecaseParams extends Equatable {
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String password;
  final String? gender;
  final String? age;

  const RegisterUsecaseParams({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.password,
    this.gender,
    this.age,
  });

  @override
  List<Object?> get props => [firstName, lastName, username, email, password, gender, age];
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
        firstName: params.firstName,
        lastName: params.lastName,
        username: params.username,
        email: params.email,
        password: params.password,
        gender: params.gender,
        age: params.age,
      ),
    );
  }
}
