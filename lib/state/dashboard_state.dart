class DashboardState {
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
}

