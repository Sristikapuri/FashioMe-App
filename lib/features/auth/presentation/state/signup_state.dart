import 'package:equatable/equatable.dart';

class SignupState extends Equatable {
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final String? errorMessage;

  const SignupState({
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.isLoading = false,
    this.errorMessage,
  });

  const SignupState.initial()
      : obscurePassword = true,
        obscureConfirmPassword = true,
        isLoading = false,
        errorMessage = null;

  SignupState copyWith({
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SignupState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword:
          obscureConfirmPassword ?? this.obscureConfirmPassword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        obscurePassword,
        obscureConfirmPassword,
        isLoading,
        errorMessage,
      ];
}
