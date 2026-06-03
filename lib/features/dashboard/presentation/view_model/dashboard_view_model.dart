import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardViewModel extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    return const DashboardState.initial();
  }

  void setIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }
}
