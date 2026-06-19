import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';

abstract interface class IDashboardStateRepository {
  Future<Either<Failure, Map<String, dynamic>>> read();
  Future<Either<Failure, bool>> write(Map<String, dynamic> payload);
}

