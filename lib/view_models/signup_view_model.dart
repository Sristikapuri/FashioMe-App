import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/signup_state.dart';

final signupViewModelProvider =
    NotifierProvider<SignupViewModel, SignupState>(SignupViewModel.new);

class SignupViewModel extends Notifier<SignupState> {
  @override
  SignupState build() => const SignupState.initial();

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      obscureConfirmPassword: !state.obscureConfirmPassword,
    );
  }
}

