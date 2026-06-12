import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/dashboard/data/repositories/dashboard_repository.dart'
    as dashboard_repo;
import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final getDashboardDataUsecaseProvider = Provider<GetDashboardDataUsecase>((ref) {
  return GetDashboardDataUsecase(
    dashboardRepository: ref.read(dashboard_repo.dashboardRepositoryProvider),
  );
});

class GetDashboardDataUsecase implements UsecaseWithoutParams<DashboardEntity> {
  GetDashboardDataUsecase({required IDashboardRepository dashboardRepository})
      : _dashboardRepository = dashboardRepository;

  final IDashboardRepository _dashboardRepository;

  @override
  Future<Either<Failure, DashboardEntity>> call() {
    return _dashboardRepository.getDashboardData();
  }
}
