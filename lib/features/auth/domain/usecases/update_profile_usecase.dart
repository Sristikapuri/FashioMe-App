import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/entities/uploaded_file.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfileUsecaseParams {
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? gender;
  final int? age;
  final UploadedFile? profileImage;
  final String? password;

  const UpdateProfileUsecaseParams({
    this.firstName,
    this.lastName,
    this.username,
    this.gender,
    this.age,
    this.profileImage,
    this.password,
  });
}

class UpdateProfileUsecase
    implements UsecaseWithParams<AuthEntity, UpdateProfileUsecaseParams> {
  UpdateProfileUsecase({required IAuthRepository authRepository})
    : _authRepository = authRepository;

  final IAuthRepository _authRepository;

  @override
  Future<Either<Failure, AuthEntity>> call(UpdateProfileUsecaseParams params) {
    return _authRepository.updateProfile(
      firstName: params.firstName,
      lastName: params.lastName,
      username: params.username,
      gender: params.gender,
      age: params.age,
      profileImage: params.profileImage,
      password: params.password,
    );
  }
}
