import 'package:equatable/equatable.dart';

class OnboardingState extends Equatable {
  final int currentIndex;
  final bool isCompleting;

  const OnboardingState({this.currentIndex = 0, this.isCompleting = false});

  const OnboardingState.initial() : currentIndex = 0, isCompleting = false;

  OnboardingState copyWith({int? currentIndex, bool? isCompleting}) {
    return OnboardingState(
      currentIndex: currentIndex ?? this.currentIndex,
      isCompleting: isCompleting ?? this.isCompleting,
    );
  }

  @override
  List<Object?> get props => [currentIndex, isCompleting];
}
