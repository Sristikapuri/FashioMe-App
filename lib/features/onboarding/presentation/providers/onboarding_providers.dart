import 'package:fashio_me/features/onboarding/presentation/state/onboarding_state.dart';
import 'package:fashio_me/features/onboarding/presentation/view_model/onboarding_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(
      OnboardingViewModel.new,
    );
