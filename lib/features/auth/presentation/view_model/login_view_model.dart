import 'package:fashio_me/features/auth/presentation/providers/auth_providers.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_session_providers.dart';
import 'package:fashio_me/features/auth/domain/usecases/login_usecase.dart';
import 'package:fashio_me/features/auth/presentation/state/login_state.dart';
import 'package:fashio_me/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginViewModel extends Notifier<LoginState> {
  late final LoginUsecase _loginUsecase;

  @override
  LoginState build() {
    _loginUsecase = ref.read(loginUsecaseProvider);
    return const LoginState.initial();
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<bool> login({required String email, required String password}) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty) {
      state = state.copyWith(errorMessage: 'Email is required.');
      return false;
    }
    if (!RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(trimmedEmail)) {
      state = state.copyWith(errorMessage: 'Enter a valid email address.');
      return false;
    }
    if (trimmedPassword.isEmpty) {
      state = state.copyWith(errorMessage: 'Password is required.');
      return false;
    }
    if (trimmedPassword.length < 6) {
      state = state.copyWith(
        errorMessage: 'Password must be at least 6 characters.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _loginUsecase(
      LoginUsecaseParams(email: trimmedEmail, password: trimmedPassword),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (entity) {
        ref.read(authSessionViewModelProvider.notifier).setUser(entity);
        state = state.copyWith(isLoading: false);

        Future.microtask(() {
          ref.read(dashboardViewModelProvider.notifier).clearCacheAndRefresh();
        });
        return true;
      },
    );
  }
}
