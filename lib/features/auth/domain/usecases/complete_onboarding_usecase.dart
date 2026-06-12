import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/auth/data/repositories/auth_repository.dart'
    as auth_repo;
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final completeOnboardingUsecaseProvider =
    Provider<CompleteOnboardingUsecase>((ref) {
  return CompleteOnboardingUsecase(
    authRepository: ref.read(auth_repo.authRepositoryProvider),
  );
});

class CompleteOnboardingUsecaseParams extends Equatable {
  const CompleteOnboardingUsecaseParams();

  @override
  List<Object?> get props => [];
}

class CompleteOnboardingUsecase
    implements UsecaseWithParams<bool, CompleteOnboardingUsecaseParams> {
  CompleteOnboardingUsecase({required IAuthRepository authRepository})
      : _authRepository = authRepository;

  final IAuthRepository _authRepository;

  @override
  Future<Either<Failure, bool>> call(CompleteOnboardingUsecaseParams params) {
    return _authRepository.completeOnboarding();
  }
}
