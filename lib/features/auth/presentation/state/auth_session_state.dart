import 'package:equatable/equatable.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';

/// Global signed-in user session (dashboard, profile).
class AuthSessionState extends Equatable {
  final AuthEntity? user;
  final bool isRestoring;
  final bool isLoggingOut;
  final String? errorMessage;

  const AuthSessionState({
    this.user,
    this.isRestoring = false,
    this.isLoggingOut = false,
    this.errorMessage,
  });

  const AuthSessionState.initial()
      : user = null,
        isRestoring = false,
        isLoggingOut = false,
        errorMessage = null;

  bool get isAuthenticated => user != null;

  AuthSessionState copyWith({
    AuthEntity? user,
    bool? isRestoring,
    bool? isLoggingOut,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthSessionState(
      user: clearUser ? null : (user ?? this.user),
      isRestoring: isRestoring ?? this.isRestoring,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [user, isRestoring, isLoggingOut, errorMessage];
}
