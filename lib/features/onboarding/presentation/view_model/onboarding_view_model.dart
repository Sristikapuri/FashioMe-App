import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_initial_route_usecase.dart';
import 'package:fashio_me/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:fashio_me/features/onboarding/domain/entities/onboarding_item.dart';
import 'package:fashio_me/features/onboarding/presentation/state/onboarding_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingViewModel extends Notifier<OnboardingState> {
  late final GetInitialRouteUsecase _getInitialRouteUsecase;
  late final IOnboardingRepository _onboardingRepository;

  @override
  OnboardingState build() {
    _getInitialRouteUsecase = ref.read(getInitialRouteUsecaseProvider);
    _onboardingRepository = ref.read(onboardingRepositoryProvider);
    return const OnboardingState.initial();
  }

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  Future<String?> resolveRedirectRoute() async {
    final result = await _getInitialRouteUsecase();
    return result.fold(
      (_) => null,
      (route) => route == 'onboarding' ? null : route,
    );
  }

  Future<bool> completeOnboarding() async {
    state = state.copyWith(isCompleting: true);
    final result = await _onboardingRepository.completeOnboarding();
    return result.fold(
      (_) {
        state = state.copyWith(isCompleting: false);
        return false;
      },
      (_) {
        state = state.copyWith(isCompleting: false);
        return true;
      },
    );
  }

  bool isLastPage(int index) => index >= kOnboardingItems.length - 1;
}
