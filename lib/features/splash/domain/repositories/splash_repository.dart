import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';

abstract interface class ISplashRepository {
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, bool>> hasCompletedOnboarding();
}
