import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/features/auth/data/repositories/auth_repository.dart'
    as auth_data;
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:fashio_me/features/auth/domain/usecases/complete_onboarding_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_initial_route_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/is_logged_in_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/login_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/register_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/whoami_usecase.dart';
import 'package:fashio_me/features/dashboard/data/datasources/remote/dashboard_home_remote_datasource.dart';
import 'package:fashio_me/features/dashboard/data/repositories/dashboard_home_repository_impl.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_home_repository.dart';
import 'package:fashio_me/features/dashboard/data/repositories/dashboard_repository.dart'
    as dashboard_data;
import 'package:fashio_me/features/dashboard/data/repositories/dashboard_state_repository_impl.dart'
    as dashboard_state_data;
import 'package:fashio_me/features/dashboard/data/repositories/dashboard_upload_repository_impl.dart'
    as dashboard_upload_data;
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_state_repository.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_upload_repository.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/get_dashboard_data_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/persist_dashboard_state_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/read_dashboard_state_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/upload_item_photo_usecase.dart';
import 'package:fashio_me/features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as onboarding_data;
import 'package:fashio_me/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:fashio_me/features/shop/data/repositories/shop_repository_impl.dart'
    as shop_data;
import 'package:fashio_me/features/shop/domain/repositories/shop_repository.dart';
import 'package:fashio_me/features/silhouette/data/repositories/silhouette_repository_impl.dart'
    as silhouette_data;
import 'package:fashio_me/features/silhouette/domain/repositories/silhouette_repository.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/clear_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/get_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/has_completed_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/save_silhouette_profile_usecase.dart';



final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return ref.read(auth_data.authRepositoryProvider);
});

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

final deleteAccountUsecaseProvider = Provider<DeleteAccountUsecase>((ref) {
  return DeleteAccountUsecase(authRepository: ref.read(authRepositoryProvider));
});

final completeOnboardingUsecaseProvider = Provider<CompleteOnboardingUsecase>(
  (ref) {
    return CompleteOnboardingUsecase(
      authRepository: ref.read(authRepositoryProvider),
    );
  },
);

final isLoggedInUsecaseProvider = Provider<IsLoggedInUsecase>((ref) {
  return IsLoggedInUsecase(authRepository: ref.read(authRepositoryProvider));
});

final getInitialRouteUsecaseProvider = Provider<GetInitialRouteUsecase>((ref) {
  return GetInitialRouteUsecase(
    authRepository: ref.read(authRepositoryProvider),
  );
});

final whoamiUsecaseProvider = Provider<WhoamiUsecase>((ref) {
  return WhoamiUsecase(authRepository: ref.read(authRepositoryProvider));
});

final updateProfileUsecaseProvider = Provider<UpdateProfileUsecase>((ref) {
  return UpdateProfileUsecase(authRepository: ref.read(authRepositoryProvider));
});

final onboardingRepositoryProvider = Provider<IOnboardingRepository>((ref) {
  return ref.read(onboarding_data.onboardingRepositoryProvider);
});

final dashboardRepositoryProvider = Provider<IDashboardRepository>((ref) {
  return ref.read(dashboard_data.dashboardRepositoryProvider);
});

final dashboardStateRepositoryProvider =
    Provider<IDashboardStateRepository>((ref) {
      return ref.read(dashboard_state_data.dashboardStateRepositoryProvider);
    });

final dashboardUploadRepositoryProvider =
    Provider<IDashboardUploadRepository>((ref) {
      return ref.read(dashboard_upload_data.dashboardUploadRepositoryProvider);
    });

final dashboardHomeRepositoryProvider = Provider<IDashboardHomeRepository>(
  (ref) {
    return DashboardHomeRepositoryImpl(
      remoteDataSource: ref.read(dashboardHomeRemoteDataSourceProvider),
    );
  },
);

final getDashboardDataUsecaseProvider = Provider<GetDashboardDataUsecase>(
  (ref) {
    return GetDashboardDataUsecase(
      dashboardRepository: ref.read(dashboardRepositoryProvider),
    );
  },
);

final readDashboardStateUsecaseProvider =
    Provider<ReadDashboardStateUsecase>((ref) {
      return ReadDashboardStateUsecase(
        dashboardStateRepository: ref.read(dashboardStateRepositoryProvider),
      );
    });

final persistDashboardStateUsecaseProvider =
    Provider<PersistDashboardStateUsecase>((ref) {
      return PersistDashboardStateUsecase(
        dashboardStateRepository: ref.read(dashboardStateRepositoryProvider),
      );
    });

final uploadItemPhotoUsecaseProvider = Provider<UploadItemPhotoUsecase>((ref) {
  return UploadItemPhotoUsecase(
    dashboardUploadRepository: ref.read(dashboardUploadRepositoryProvider),
  );
});

final shopRepositoryProvider = Provider<IShopRepository>((ref) {
  return ref.read(shop_data.shopRepositoryProvider);
});

final silhouetteRepositoryProvider = Provider<ISilhouetteRepository>((ref) {
  return ref.read(silhouette_data.silhouetteRepositoryProvider);
});

final clearSilhouetteProfileUsecaseProvider =
    Provider<ClearSilhouetteProfileUsecase>((ref) {
      return ClearSilhouetteProfileUsecase(
        silhouetteRepository: ref.read(silhouetteRepositoryProvider),
      );
    });

final getSilhouetteProfileUsecaseProvider =
    Provider<GetSilhouetteProfileUsecase>((ref) {
      return GetSilhouetteProfileUsecase(
        silhouetteRepository: ref.read(silhouetteRepositoryProvider),
      );
    });

final hasCompletedSilhouetteProfileUsecaseProvider =
    Provider<HasCompletedSilhouetteProfileUsecase>((ref) {
      return HasCompletedSilhouetteProfileUsecase(
        silhouetteRepository: ref.read(silhouetteRepositoryProvider),
      );
    });

final saveSilhouetteProfileUsecaseProvider =
    Provider<SaveSilhouetteProfileUsecase>((ref) {
      return SaveSilhouetteProfileUsecase(
        silhouetteRepository: ref.read(silhouetteRepositoryProvider),
      );
    });
