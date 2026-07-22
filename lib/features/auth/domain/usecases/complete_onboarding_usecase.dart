import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';

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
