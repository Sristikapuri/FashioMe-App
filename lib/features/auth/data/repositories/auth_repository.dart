import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/data/datasources/auth_datasource.dart';
import 'package:fashio_me/features/auth/data/models/auth_model.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/entities/uploaded_file.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
class AuthRepository implements IAuthRepository {
  AuthRepository({
    required IAuthDataSource remoteDataSource,
    required IAuthDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final IAuthDataSource _remoteDataSource;
  final IAuthDataSource _localDataSource;

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

  /// Strips the Dart 'Exception: ' prefix so messages shown to users are clean.
  static String _cleanError(Object e) {
    final raw = e.toString();
    if (raw.startsWith('Exception: ')) return raw.substring('Exception: '.length);
    return raw;
  }

  bool _isServerResponseError(Object error) {
    if (error is DioException) {
      return error.response != null;
    }
    return false;
  }

  String _extractErrorMessage(Object error, String defaultFallback) {
    if (error is DioException && error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        final msg = data['responseMessage'] ?? data['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
    }
    final str = error.toString().replaceAll('Exception: ', '').trim();
    return str.isNotEmpty ? str : defaultFallback;
  }

  @override
  Future<Either<Failure, AuthEntity>> register(AuthEntity entity) async {
    final normalized = _normalize(entity);
    final model = AuthModel.fromEntity(normalized);

    // 1. Try remote backend registration first
    try {
      final registered = await _remoteDataSource.register(model);
      if (registered) {
        // Sync registered model to local Hive
        try {
          await _localDataSource.register(model);
        } catch (_) {}
        return Right(model.toEntity());
      }
    } catch (e) {
      // ONLY abort if backend server was reached and returned an explicit HTTP error (e.g. duplicate user)
      if (_isServerResponseError(e)) {
        return Left(ApiFailure(message: _extractErrorMessage(e, 'Registration failed.')));
      }
      // If server could not be reached (offline / no route to host), fall through to Hive local registration!
    }

    // 2. Offline fallback: register user in local Hive storage
    try {
      final registeredLocal = await _localDataSource.register(model);
      if (registeredLocal) {
        return Right(model.toEntity());
      }
      return const Left(ValidationFailure(message: 'Offline registration failed.'));
    } catch (e) {
      return Left(LocalDatabaseFailure(message: 'Offline registration error: ${_cleanError(e)}'));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> login(
    String email,
    String password,
  ) async {
    final cleanEmail = email.trim().toLowerCase();

    // 1. Try remote backend login first
    try {
      final user = await _remoteDataSource.login(cleanEmail, password);
      if (user != null) {
        final authId = user.authId;
        if (authId != null) {
          await _remoteDataSource.saveSession(authId);
          // Sync to local Hive
          try {
            await _localDataSource.register(user);
          } catch (_) {}
          return Right(user.toEntity());
        }
      }
    } catch (e) {
      // ONLY abort if backend server was reached and returned an explicit HTTP error (e.g. 400 bad credentials)
      if (_isServerResponseError(e)) {
        return Left(ApiFailure(message: _extractErrorMessage(e, 'Invalid email or password.')));
      }
      // If server could not be reached (offline / no route to host), fall through to Hive local login!
    }

    // 2. Offline fallback: verify against local Hive database
    try {
      final localUser = await _localDataSource.login(cleanEmail, password);
      if (localUser != null && localUser.authId != null) {
        return Right(localUser.toEntity());
      }
      return const Left(
        LocalDatabaseFailure(
          message: 'Account not found on this device while offline. Please create an account or connect to Wi-Fi.',
        ),
      );
    } catch (e) {
      return Left(LocalDatabaseFailure(message: 'Offline login error: ${_cleanError(e)}'));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      if (user != null) return Right(user.toEntity());
    } catch (_) {}

    try {
      final localUser = await _localDataSource.getCurrentUser();
      if (localUser != null) return Right(localUser.toEntity());
    } catch (_) {}

    return const Left(ApiFailure(message: 'No user logged in.'));
  }

  @override
  Future<Either<Failure, AuthEntity>> whoami() async {
    try {
      final user = await _remoteDataSource.whoami();
      if (user != null) return Right(user.toEntity());
    } catch (_) {}

    try {
      final localUser = await _localDataSource.getCurrentUser();
      if (localUser != null) return Right(localUser.toEntity());
    } catch (_) {}

    return const Left(ApiFailure(message: 'Failed to fetch user data.'));
  }

  @override
  Future<Either<Failure, bool>> forgotPassword(String email) async {
    try {
      await _remoteDataSource.forgotPassword(email);
      return const Right(true);
    } catch (e) {
      return Left(ApiFailure(message: _cleanError(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        email: email,
        token: token,
        password: password,
      );
      return const Right(true);
    } catch (e) {
      return Left(ApiFailure(message: _cleanError(e)));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAccount() async {
    try {
      return Right(await _remoteDataSource.deleteAccount());
    } catch (e) {
      return Left(ApiFailure(message: _cleanError(e)));
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
      final user = await _remoteDataSource.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        gender: gender,
        age: age,
        profileImage: profileImage == null ? null : File(profileImage.path),
        password: password,
      );
      if (user != null) return Right(user.toEntity());
    } catch (_) {}

    // Local fallback update
    try {
      final user = await _localDataSource.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        gender: gender,
        age: age,
        profileImage: profileImage == null ? null : File(profileImage.path),
        password: password,
      );
      if (user != null) return Right(user.toEntity());
    } catch (e) {
      return Left(ApiFailure(message: _cleanError(e)));
    }
    return const Left(ApiFailure(message: 'Failed to update profile.'));
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {}
    try {
      await _localDataSource.logout();
    } catch (_) {}
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> isEmailExists(String email) async {
    try {
      final exists = await _remoteDataSource.isEmailExists(email);
      return Right(exists);
    } catch (_) {
      return Right(await _localDataSource.isEmailExists(email));
    }
  }


  @override
  Future<Either<Failure, bool>> completeOnboarding() async {
    try {
      await _remoteDataSource.completeOnboarding();
    } catch (_) {}
    await _localDataSource.completeOnboarding();
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> hasCompletedOnboarding() async {
    if (_localDataSource.hasCompletedOnboarding()) {
      return const Right(true);
    }
    try {
      return Right(_remoteDataSource.hasCompletedOnboarding());
    } catch (_) {
      return Right(_localDataSource.hasCompletedOnboarding());
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    if (_localDataSource.isLoggedIn()) return const Right(true);
    try {
      return Right(_remoteDataSource.isLoggedIn());
    } catch (_) {
      return Right(_localDataSource.isLoggedIn());
    }
  }

  @override
  Future<Either<Failure, String>> getInitialRoute() async {
    try {
      // 1. Check local session state first
      final hasLocalSession = _localDataSource.isLoggedIn();

      if (hasLocalSession) {
        // Attempt fast remote verification (3s timeout)
        try {
          final whoamiResult = await _remoteDataSource
              .whoami()
              .timeout(const Duration(seconds: 3));
          if (whoamiResult != null) return const Right('dashboard');
        } catch (_) {
          // If offline or network timeout, DO NOT log out — stay authenticated offline!
          return const Right('dashboard');
        }
        // Token is invalid, clear local session
        await _localDataSource.logout();
      }

      if (_localDataSource.hasCompletedOnboarding()) {
        return const Right('login');
      }

      return const Right('onboarding');
    } catch (_) {
      return const Right('onboarding');
    }
  }
}

