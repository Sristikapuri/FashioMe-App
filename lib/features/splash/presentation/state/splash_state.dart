import 'package:equatable/equatable.dart';

class SplashState extends Equatable {
  final bool isResolvingRoute;
  final String? targetRoute;
  final String? errorMessage;

  const SplashState({
    this.isResolvingRoute = false,
    this.targetRoute,
    this.errorMessage,
  });

  const SplashState.initial()
      : isResolvingRoute = false,
        targetRoute = null,
        errorMessage = null;

  SplashState copyWith({
    bool? isResolvingRoute,
    String? targetRoute,
    String? errorMessage,
    bool clearRoute = false,
    bool clearError = false,
  }) {
    return SplashState(
      isResolvingRoute: isResolvingRoute ?? this.isResolvingRoute,
      targetRoute: clearRoute ? null : (targetRoute ?? this.targetRoute),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [isResolvingRoute, targetRoute, errorMessage];
}
