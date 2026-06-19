import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/dashboard/data/repositories/dashboard_state_repository_impl.dart'
    as dashboard_state_repo;
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_state_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final readDashboardStateUsecaseProvider = Provider<ReadDashboardStateUsecase>((ref) {
  return ReadDashboardStateUsecase(
    dashboardStateRepository: ref.read(dashboard_state_repo.dashboardStateRepositoryProvider),
  );
});

class ReadDashboardStateUsecase
    implements UsecaseWithoutParams<Map<String, dynamic>> {
  ReadDashboardStateUsecase({
    required IDashboardStateRepository dashboardStateRepository,
  }) : _dashboardStateRepository = dashboardStateRepository;

  final IDashboardStateRepository _dashboardStateRepository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call() {
    return _dashboardStateRepository.read();
  }
}

