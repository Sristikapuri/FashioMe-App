import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';

abstract interface class IAuthRepository {
  Future<Either<Failure, AuthEntity>> register(AuthEntity entity);
  Future<Either<Failure, AuthEntity>> login(String email, String password);
  Future<Either<Failure, AuthEntity>> getCurrentUser();
  Future<Either<Failure, AuthEntity>> whoami();
  Future<Either<Failure, bool>> forgotPassword(String email);
  Future<Either<Failure, bool>> resetPassword({
    required String email,
    required String token,
    required String password,
  });
  Future<Either<Failure, bool>> deleteAccount();
  Future<Either<Failure, AuthEntity>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? gender,
    int? age,
    File? profileImage,
    String? password,
  });
  Future<Either<Failure, bool>> logout();
  Future<Either<Failure, bool>> isEmailExists(String email);
  Future<Either<Failure, bool>> completeOnboarding();
  Future<Either<Failure, bool>> hasCompletedOnboarding();
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, String>> getInitialRoute();
}
