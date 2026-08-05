import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/data/datasources/auth_datasource.dart';
import 'package:fashio_me/features/auth/data/models/auth_model.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/entities/uploaded_file.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
class AuthRepository implements IAuthRepository {
  AuthRepository({required IAuthDataSource authDataSource})
    : _authDataSource = authDataSource;

  final IAuthDataSource _authDataSource;

  AuthEntity _normalize(AuthEntity entity) {
    return AuthEntity(
      authId: entity.authId,
      firstName: entity.firstName.trim(),
      lastName: entity.lastName.trim(),
      username: entity.username.trim(),
      email: entity.email.trim().toLowerCase(),
      password: entity.password,
      gender: entity.gender?.trim(),
      age: entity.age?.trim(),
    );
  }

  @override
  Future<Either<Failure, AuthEntity>> register(AuthEntity entity) async {
    try {
      final normalized = _normalize(entity);
      final model = AuthModel.fromEntity(normalized);
      final registered = await _authDataSource.register(model);
      if (!registered) {
        return const Left(ValidationFailure(message: 'Registration failed.'));
      }

      return Right(model.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login(
    String email,
    String password,
  ) async {
    try {
      final user = await _authDataSource.login(email, password);
      if (user == null) {
        return const Left(
          LocalDatabaseFailure(message: 'Invalid email or password.'),
        );
      }

      final authId = user.authId;
      if (authId == null) {
        return const Left(ApiFailure(message: 'Invalid email or password.'));
      }

      await _authDataSource.saveSession(authId);
      return Right(user.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    try {
      final user = await _authDataSource.getCurrentUser();
      if (user == null) {
        return const Left(ApiFailure(message: 'No user logged in.'));
      }
      return Right(user.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> whoami() async {
    try {
      final user = await _authDataSource.whoami();
      if (user == null) {
        return const Left(ApiFailure(message: 'Failed to fetch user data.'));
      }
      return Right(user.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> forgotPassword(String email) async {
    try {
      await _authDataSource.forgotPassword(email);
      return const Right(true);
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    try {
      await _authDataSource.resetPassword(
        email: email,
        token: token,
        password: password,
      );
      return const Right(true);
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAccount() async {
    try {
      return Right(await _authDataSource.deleteAccount());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? gender,
    int? age,
    UploadedFile? profileImage,
    String? password,
  }) async {
    try {
      final user = await _authDataSource.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        gender: gender,
        age: age,
        profileImage: profileImage == null ? null : File(profileImage.path),
        password: password,
      );
      if (user == null) {
        return const Left(ApiFailure(message: 'Failed to update profile.'));
      }
      return Right(user.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      final result = await _authDataSource.logout();
      return Right(result);
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailExists(String email) async {
    try {
      return Right(await _authDataSource.isEmailExists(email));
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> completeOnboarding() async {
    try {
      await _authDataSource.completeOnboarding();
      return const Right(true);
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasCompletedOnboarding() async {
    try {
      return Right(_authDataSource.hasCompletedOnboarding());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      return Right(_authDataSource.isLoggedIn());
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getInitialRoute() async {
    try {
      // Check if user is logged in with valid token
      if (_authDataSource.isLoggedIn()) {
        final whoamiResult = await _authDataSource.whoami();
        if (whoamiResult != null) {
          // User is authenticated, check if silhouette is completed
          // This will be handled in splash page based on silhouette status
          return const Right('dashboard');
        }
        // Token is invalid, clear local session
        await _authDataSource.logout();
      }


      if (_authDataSource.hasCompletedOnboarding()) {
        return const Right('login');
      }

      return const Right('onboarding');
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }
}
