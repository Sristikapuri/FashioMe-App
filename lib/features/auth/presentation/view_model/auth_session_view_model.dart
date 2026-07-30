import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/entities/uploaded_file.dart';
import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/whoami_usecase.dart';
import 'package:fashio_me/features/auth/presentation/state/auth_session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSessionViewModel extends Notifier<AuthSessionState> {
  late final GetCurrentUserUsecase _getCurrentUserUsecase;
  DeleteAccountUsecase? _deleteAccountUsecase;
  late final LogoutUsecase _logoutUsecase;
  late final WhoamiUsecase _whoamiUsecase;
  late final UpdateProfileUsecase _updateProfileUsecase;

  @override
  AuthSessionState build() {
    _getCurrentUserUsecase = ref.read(getCurrentUserUsecaseProvider);
    _logoutUsecase = ref.read(logoutUsecaseProvider);
    _whoamiUsecase = ref.read(whoamiUsecaseProvider);
    _updateProfileUsecase = ref.read(updateProfileUsecaseProvider);
    return const AuthSessionState.initial();
  }

  void setUser(AuthEntity user) {
    state = state.copyWith(user: user, clearError: true);
  }

  Future<void> restoreSession() async {
    state = state.copyWith(isRestoring: true, clearError: true);
    final result = await _getCurrentUserUsecase();
    state = result.fold(
      (_) => state.copyWith(isRestoring: false, clearUser: true),
      (user) => state.copyWith(isRestoring: false, user: user),
    );
  }

  Future<Either<Failure, AuthEntity>> getCurrentUser() async {
    return await _getCurrentUserUsecase();
  }

  Future<bool> logout() async {
    state = state.copyWith(isLoggingOut: true, clearError: true);
    final result = await _logoutUsecase(const LogoutUsecaseParams());
    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoggingOut: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = const AuthSessionState.initial();
        return true;
      },
    );
  }

  Future<Either<String, AuthEntity>> whoami() async {
    final result = await _whoamiUsecase();
    return result.fold(
      (failure) => Left(failure.message),
      (user) => Right(user),
    );
  }

  Future<Either<String, AuthEntity>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? gender,
    int? age,
    File? profileImage,
    String? password,
  }) async {
    final result = await _updateProfileUsecase(
      UpdateProfileUsecaseParams(
        firstName: firstName,
        lastName: lastName,
        username: username,
        gender: gender,
        age: age,
        profileImage: profileImage == null ? null : UploadedFile(profileImage.path),
        password: password,
      ),
    );
    return result.fold((failure) => Left(failure.message), (user) {
      setUser(user);
      return Right(user);
    });
  }

  Future<bool> deleteAccount() async {
    final usecase = _deleteAccountUsecase ??= ref.read(
      deleteAccountUsecaseProvider,
    );
    final result = await usecase!();
    if (result.isLeft()) {
      return false;
    }

    await logout();
    return true;
  }
}
