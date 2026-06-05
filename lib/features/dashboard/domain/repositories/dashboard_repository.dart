import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entity.dart';

abstract interface class IDashboardRepository {
  Future<Either<Failure, DashboardEntity>> getDashboardData();
}
