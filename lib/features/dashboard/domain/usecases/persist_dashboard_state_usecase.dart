import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/dashboard/data/repositories/dashboard_state_repository_impl.dart'
    as dashboard_state_repo;
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_state_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final persistDashboardStateUsecaseProvider =
    Provider<PersistDashboardStateUsecase>((ref) {
  return PersistDashboardStateUsecase(
    dashboardStateRepository:
        ref.read(dashboard_state_repo.dashboardStateRepositoryProvider),
  );
});

class PersistDashboardStateUsecase
    implements UsecaseWithParams<bool, PersistDashboardStateParams> {
  PersistDashboardStateUsecase({
    required IDashboardStateRepository dashboardStateRepository,
  }) : _dashboardStateRepository = dashboardStateRepository;

  final IDashboardStateRepository _dashboardStateRepository;

  @override
  Future<Either<Failure, bool>> call(PersistDashboardStateParams params) {
    return _dashboardStateRepository.write(params.payload);
  }
}

class PersistDashboardStateParams {
  const PersistDashboardStateParams({required this.payload});

  final Map<String, dynamic> payload;
}

