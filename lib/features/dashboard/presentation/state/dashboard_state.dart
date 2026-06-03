import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  final int currentIndex;

  const DashboardState({
    this.currentIndex = 0,
  });

  const DashboardState.initial() : currentIndex = 0;

  DashboardState copyWith({int? currentIndex}) {
    return DashboardState(
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [currentIndex];
}
