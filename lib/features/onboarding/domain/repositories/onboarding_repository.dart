import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/onboarding/domain/entities/onboarding_item.dart';

abstract interface class IOnboardingRepository {
  Future<Either<Failure, List<OnboardingItem>>> getOnboardingItems();
  Future<Either<Failure, bool>> completeOnboarding();
  Future<Either<Failure, bool>> hasCompletedOnboarding();
}
