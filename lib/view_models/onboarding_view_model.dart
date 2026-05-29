import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/onboarding_state.dart';

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
  OnboardingViewModel.new,
);

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState.initial();

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }
}

