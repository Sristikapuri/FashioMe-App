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
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    final trimmedConfirm = confirmPassword.trim();

    if (trimmedName.isEmpty) {
      state = state.copyWith(errorMessage: 'Full name is required.');
      return false;
    }
    if (trimmedName.length < 3) {
      state = state.copyWith(errorMessage: 'Full name must be at least 3 characters.');
      return false;
    }

    if (trimmedEmail.isEmpty) {
      state = state.copyWith(errorMessage: 'Email is required.');
      return false;
    }
    if (!RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$').hasMatch(trimmedEmail)) {
      state = state.copyWith(errorMessage: 'Enter a valid email address.');
      return false;
    }

    if (trimmedPassword.isEmpty) {
      state = state.copyWith(errorMessage: 'Password is required.');
      return false;
    }
    if (trimmedPassword.length < 6) {
      state = state.copyWith(errorMessage: 'Password must be at least 6 characters.');
      return false;
    }

    if (trimmedConfirm.isEmpty) {
      state = state.copyWith(errorMessage: 'Confirm password is required.');
      return false;
    }
    if (trimmedPassword != trimmedConfirm) {
      state = state.copyWith(errorMessage: 'Passwords do not match.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _registerUsecase(
      RegisterUsecaseParams(
        fullName: trimmedName,
        email: trimmedEmail,
        password: trimmedPassword,
      ),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }
}
