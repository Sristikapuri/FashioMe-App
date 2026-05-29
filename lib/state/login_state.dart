class LoginState {
  final bool obscurePassword;

  const LoginState({
    this.obscurePassword = true,
  });

  const LoginState.initial() : obscurePassword = true;

  LoginState copyWith({
    bool? obscurePassword,
  }) {
    return LoginState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

