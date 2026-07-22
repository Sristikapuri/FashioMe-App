import 'package:fashio_me/features/dashboard/presentation/state/dashboard_state.dart';
import 'package:fashio_me/features/dashboard/presentation/view_model/dashboard_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'dashboard_repository_providers.dart';

final dashboardViewModelProvider =
    NotifierProvider<DashboardViewModel, DashboardState>(
      DashboardViewModel.new,
    );
