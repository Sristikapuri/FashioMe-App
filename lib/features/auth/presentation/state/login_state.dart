import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;

  const LoginState({
    this.obscurePassword = true,
    this.isLoading = false,
    this.errorMessage,
  });

  const LoginState.initial()
    : obscurePassword = true,
      isLoading = false,
      errorMessage = null;

  LoginState copyWith({
    bool? obscurePassword,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoginState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [obscurePassword, isLoading, errorMessage];
}
