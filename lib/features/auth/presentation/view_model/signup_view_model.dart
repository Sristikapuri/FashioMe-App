import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/features/auth/domain/usecases/register_usecase.dart';
import 'package:fashio_me/features/auth/presentation/state/signup_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignupViewModel extends Notifier<SignupState> {
  late final RegisterUsecase _registerUsecase;

  @override
  SignupState build() {
    _registerUsecase = ref.read(registerUsecaseProvider);
    return const SignupState.initial();
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      obscureConfirmPassword: !state.obscureConfirmPassword,
    );
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? gender,
    String? age,
  }) async {
    final trimmedFirstName = firstName.trim();
    final trimmedLastName = lastName.trim();
    final trimmedUsername = username.trim();
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    final trimmedConfirmPassword = confirmPassword.trim();

    if (trimmedFirstName.isEmpty) {
      state = state.copyWith(errorMessage: 'First name is required.');
      return false;
    }
    if (trimmedFirstName.length < 2) {
      state = state.copyWith(
        errorMessage: 'First name must be at least 2 characters.',
      );
      return false;
    }

    if (trimmedLastName.isEmpty) {
      state = state.copyWith(errorMessage: 'Last name is required.');
      return false;
    }
    if (trimmedLastName.length < 2) {
      state = state.copyWith(
        errorMessage: 'Last name must be at least 2 characters.',
      );
      return false;
    }

    if (trimmedUsername.isEmpty) {
      state = state.copyWith(errorMessage: 'Username is required.');
      return false;
    }
    if (trimmedUsername.length < 3) {
      state = state.copyWith(
        errorMessage: 'Username must be at least 3 characters.',
      );
      return false;
    }

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
    if (trimmedConfirmPassword.isEmpty) {
      state = state.copyWith(errorMessage: 'Confirm password is required.');
      return false;
    }
    if (trimmedConfirmPassword.length < 6) {
      state = state.copyWith(
        errorMessage: 'Confirm password must be at least 6 characters.',
      );
      return false;
    }
    if (trimmedPassword != trimmedConfirmPassword) {
      state = state.copyWith(errorMessage: 'Passwords do not match.');
      return false;
    }

    if (gender == null || gender.isEmpty) {
      state = state.copyWith(errorMessage: 'Gender is required.');
      return false;
    }

    if (age == null || age.isEmpty) {
      state = state.copyWith(errorMessage: 'Age is required.');
      return false;
    }
    final parsedAge = int.tryParse(age.trim());
    if (parsedAge == null || parsedAge < 1 || parsedAge > 100) {
      state = state.copyWith(errorMessage: 'Please enter a valid age (1-100).');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _registerUsecase(
        RegisterUsecaseParams(
          firstName: trimmedFirstName,
          lastName: trimmedLastName,
          username: trimmedUsername,
          email: trimmedEmail,
          password: trimmedPassword,
          gender: gender,
          age: age,
        ),
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
    if (msg.isEmpty) return 'Registration failed. Please try again.';
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
