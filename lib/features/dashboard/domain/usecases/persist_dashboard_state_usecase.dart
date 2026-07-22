import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_state_repository.dart';

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
