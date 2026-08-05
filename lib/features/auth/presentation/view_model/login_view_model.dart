import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/features/auth/domain/usecases/login_usecase.dart';
import 'package:fashio_me/features/auth/presentation/state/login_state.dart';
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

    try {
      final result = await _loginUsecase(
        LoginUsecaseParams(email: trimmedEmail, password: trimmedPassword),
      );

      return result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: _sanitizeErrorMessage(failure.message),
          );
          return false;
        },
        (_) {
          state = state.copyWith(isLoading: false);
          return true;
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _sanitizeErrorMessage(
          e.toString().replaceAll('Exception: ', '').trim(),
        ),
      );
      return false;
    }
  }

  /// Replaces raw Dio / Socket / network error messages with a clean
  /// user-friendly message so connection errors never leak to the UI.
  static String _sanitizeErrorMessage(String msg) {
    if (msg.isEmpty) return 'Login failed. Please try again.';
    final lower = msg.toLowerCase();
    if (lower.contains('connection errored') ||
        lower.contains('connection failed') ||
        lower.contains('socketexception') ||
        lower.contains('no route to host') ||
        lower.contains('network is unreachable') ||
        lower.contains('dioexception') ||
        lower.contains('connection error') ||
        lower.contains('connection timeout') ||
        lower.contains('cannot be solved by the library')) {
      return 'You are offline. Please connect to Wi-Fi or try again later.';
    }
    return msg;
  }
}
