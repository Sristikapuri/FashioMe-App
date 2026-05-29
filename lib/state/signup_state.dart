class SignupState {
  final bool obscurePassword;
  final bool obscureConfirmPassword;

  const SignupState({
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
  });

  const SignupState.initial()
      : obscurePassword = true,
        obscureConfirmPassword = true;

  SignupState copyWith({
    bool? obscurePassword,
    bool? obscureConfirmPassword,
  }) {
    return SignupState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
    );
  }
}

