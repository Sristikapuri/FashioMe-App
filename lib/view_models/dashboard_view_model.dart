import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/dashboard_state.dart';

final dashboardViewModelProvider =
    NotifierProvider<DashboardViewModel, DashboardState>(
  DashboardViewModel.new,
);

class DashboardViewModel extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    return const DashboardState.initial();
  }

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }
}

