import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_initial_route_usecase.dart';
import 'package:fashio_me/features/splash/presentation/state/splash_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashViewModel extends Notifier<SplashState> {
  late final GetInitialRouteUsecase _getInitialRouteUsecase;

  @override
  SplashState build() {
    _getInitialRouteUsecase = ref.read(getInitialRouteUsecaseProvider);
    return const SplashState.initial();
  }

  Future<void> resolveInitialRoute() async {
    state = state.copyWith(isResolvingRoute: true, clearError: true);

    final result = await _getInitialRouteUsecase();

    state = result.fold(
      (failure) => state.copyWith(
        isResolvingRoute: false,
        errorMessage: failure.message,
        targetRoute: 'onboarding',
      ),
      (route) => state.copyWith(isResolvingRoute: false, targetRoute: route),
    );
  }

  void clearNavigationTarget() {
    state = state.copyWith(clearRoute: true);
  }

  /// Called when the overall splash timeout fires and [resolveInitialRoute]
  /// did not complete in time. Sets a safe fallback so the UI can still
  /// navigate away instead of remaining stuck on the splash screen.
  void forceFallbackRoute() {
    // If we already have a resolved route (race condition), keep it.
    if (state.targetRoute != null) return;
    state = state.copyWith(
      isResolvingRoute: false,
      targetRoute: 'onboarding',
    );
  }
}
