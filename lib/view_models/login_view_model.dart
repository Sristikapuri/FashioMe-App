import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/login_state.dart';

final loginViewModelProvider =
    NotifierProvider<LoginViewModel, LoginState>(LoginViewModel.new);

class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState.initial();

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }
}

