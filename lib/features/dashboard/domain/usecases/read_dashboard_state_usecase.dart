import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_state_repository.dart';

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
