import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fashio_me/features/auth/presentation/state/auth_session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSessionViewModel extends Notifier<AuthSessionState> {
  late final GetCurrentUserUsecase _getCurrentUserUsecase;
  late final LogoutUsecase _logoutUsecase;

  @override
  AuthSessionState build() {
    _getCurrentUserUsecase = ref.read(getCurrentUserUsecaseProvider);
    _logoutUsecase = ref.read(logoutUsecaseProvider);
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
}
