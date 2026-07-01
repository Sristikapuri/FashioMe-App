import 'package:fashio_me/features/auth/data/repositories/auth_repository.dart'
    as auth_repo;
import 'package:fashio_me/features/auth/domain/usecases/complete_onboarding_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_initial_route_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/is_logged_in_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/login_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/register_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/whoami_usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = auth_repo.authRepositoryProvider;

final loginUsecaseProvider = Provider<LoginUsecase>((ref) {
  return LoginUsecase(authRepository: ref.read(authRepositoryProvider));
});

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  return RegisterUsecase(authRepository: ref.read(authRepositoryProvider));
});

final getCurrentUserUsecaseProvider = Provider<GetCurrentUserUsecase>((ref) {
  return GetCurrentUserUsecase(
    authRepository: ref.read(authRepositoryProvider),
  );
});

final logoutUsecaseProvider = Provider<LogoutUsecase>((ref) {
  return LogoutUsecase(authRepository: ref.read(authRepositoryProvider));
});

final completeOnboardingUsecaseProvider =
    Provider<CompleteOnboardingUsecase>((ref) {
  return CompleteOnboardingUsecase(
    authRepository: ref.read(authRepositoryProvider),
  );
});

final isLoggedInUsecaseProvider = Provider<IsLoggedInUsecase>((ref) {
  return IsLoggedInUsecase(authRepository: ref.read(authRepositoryProvider));
});

final getInitialRouteUsecaseProvider =
    Provider<GetInitialRouteUsecase>((ref) {
  return GetInitialRouteUsecase(
    authRepository: ref.read(authRepositoryProvider),
  );
});

final whoamiUsecaseProvider = Provider<WhoamiUsecase>((ref) {
  return WhoamiUsecase(authRepository: ref.read(authRepositoryProvider));
});

final updateProfileUsecaseProvider =
    Provider<UpdateProfileUsecase>((ref) {
  return UpdateProfileUsecase(
    authRepository: ref.read(authRepositoryProvider),
  );
});
