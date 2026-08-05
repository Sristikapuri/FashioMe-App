import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/core/services/media/image_picker_service.dart';
import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/services/storage/shop_cache_service.dart';

import 'package:fashio_me/features/auth/data/repositories/auth_repository.dart'
    as auth_data;
import 'package:fashio_me/features/auth/data/datasources/remote/auth_remote_datasource.dart' as auth_remote;
import 'package:fashio_me/features/auth/data/datasources/local/auth_local_datasource.dart' as auth_local;

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
import 'package:fashio_me/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/reset_password_usecase.dart';
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
import 'package:fashio_me/features/dashboard/data/datasources/remote/dashboard_remote_datasource.dart' as dashboard_remote;
import 'package:fashio_me/features/dashboard/data/datasources/local/dashboard_local_datasource.dart' as dashboard_local;
import 'package:fashio_me/features/dashboard/data/datasources/local/dashboard_state_local_datasource.dart' as dashboard_state_local;
import 'package:fashio_me/features/dashboard/data/datasources/remote/dashboard_upload_remote_datasource.dart' as dashboard_upload_remote;
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_state_repository.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_upload_repository.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/get_dashboard_data_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/generate_recommendation_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/dashboard_home_usecases.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/persist_dashboard_state_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/read_dashboard_state_usecase.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/upload_item_photo_usecase.dart';
import 'package:fashio_me/features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as onboarding_data;
import 'package:fashio_me/features/onboarding/data/datasources/remote/onboarding_remote_datasource.dart' as onboarding_remote;
import 'package:fashio_me/features/onboarding/data/datasources/local/onboarding_local_datasource.dart' as onboarding_local;
import 'package:fashio_me/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:fashio_me/features/shop/data/repositories/shop_repository_impl.dart'
    as shop_data;
import 'package:fashio_me/features/shop/data/datasources/shop_remote_datasource.dart'
    as shop_remote;
import 'package:fashio_me/features/shop/domain/repositories/shop_repository.dart';
import 'package:fashio_me/features/shop/domain/usecases/shop_usecases.dart';
import 'package:fashio_me/features/silhouette/data/repositories/silhouette_repository_impl.dart'
    as silhouette_data;
import 'package:fashio_me/features/silhouette/data/datasources/local/silhouette_local_datasource.dart' as silhouette_local;
import 'package:fashio_me/features/silhouette/data/datasources/remote/silhouette_remote_datasource.dart' as silhouette_remote;
import 'package:fashio_me/features/silhouette/domain/repositories/silhouette_repository.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/clear_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/get_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/has_completed_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/save_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/review/data/datasources/review_remote_datasource.dart';
import 'package:fashio_me/features/review/data/repositories/review_repository_impl.dart';
import 'package:fashio_me/features/review/domain/repositories/review_repository.dart';
import 'package:fashio_me/features/review/domain/usecases/create_review_usecase.dart';
import 'package:fashio_me/features/review/domain/usecases/delete_review_usecase.dart';
import 'package:fashio_me/features/review/domain/usecases/get_my_reviews_usecase.dart';
import 'package:fashio_me/features/review/domain/usecases/get_reviews_by_clothe_usecase.dart';
import 'package:fashio_me/features/review/domain/usecases/update_review_usecase.dart';
import 'package:fashio_me/features/style_archive/data/repositories/style_archive_repository_impl.dart';
import 'package:fashio_me/features/style_archive/data/datasources/style_archive_remote_datasource.dart';
import 'package:fashio_me/features/style_archive/domain/repositories/style_archive_repository.dart';
import 'package:fashio_me/features/style_archive/domain/usecases/save_style_archive_entry_usecase.dart';
import 'package:fashio_me/features/style_archive/domain/usecases/get_style_archive_usecase.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return auth_data.AuthRepository(
    remoteDataSource: ref.read(auth_remote.authRemoteDatasourceProvider),
    localDataSource: ref.read(auth_local.authLocalDatasourceProvider),
  );
});


final imagePickerServiceProvider = Provider<ImagePickerService>(
  (ref) => PlatformImagePickerService(),
);

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

final completeOnboardingUsecaseProvider = Provider<CompleteOnboardingUsecase>((
  ref,
) {
  return CompleteOnboardingUsecase(
    authRepository: ref.read(authRepositoryProvider),
  );
});

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

final forgotPasswordUsecaseProvider = Provider<ForgotPasswordUsecase>(
  (ref) => ForgotPasswordUsecase(ref.read(authRepositoryProvider)),
);
final resetPasswordUsecaseProvider = Provider<ResetPasswordUsecase>(
  (ref) => ResetPasswordUsecase(ref.read(authRepositoryProvider)),
);

final onboardingRepositoryProvider = Provider<IOnboardingRepository>((ref) {
  return onboarding_data.OnboardingRepositoryImpl(
    remoteDataSource: ref.read(onboarding_remote.onboardingRemoteDataSourceProvider),
    localDataSource: ref.read(onboarding_local.onboardingLocalDataSourceProvider),
  );
});

final dashboardRepositoryProvider = Provider<IDashboardRepository>((ref) {
  return dashboard_data.DashboardRepository(remoteDataSource: ref.read(dashboard_remote.dashboardRemoteDataSourceProvider), localDataSource: ref.read(dashboard_local.dashboardLocalDataSourceProvider));
});

final dashboardStateRepositoryProvider = Provider<IDashboardStateRepository>((
  ref,
) {
  return dashboard_state_data.DashboardStateRepositoryImpl(localDataSource: ref.read(dashboard_state_local.dashboardStateLocalDataSourceProvider));
});

final dashboardUploadRepositoryProvider = Provider<IDashboardUploadRepository>((
  ref,
) {
  return dashboard_upload_data.DashboardUploadRepositoryImpl(remoteDataSource: ref.read(dashboard_upload_remote.dashboardUploadRemoteDataSourceProvider));
});

final dashboardHomeRepositoryProvider = Provider<IDashboardHomeRepository>((
  ref,
) {
  return DashboardHomeRepositoryImpl(
    remoteDataSource: ref.read(dashboardHomeRemoteDataSourceProvider),
  );
});

final dashboardHomeUsecasesProvider = Provider<DashboardHomeUsecases>(
  (ref) => DashboardHomeUsecases(ref.read(dashboardHomeRepositoryProvider)),
);

final generateRecommendationUsecaseProvider =
    Provider<GenerateRecommendationUsecase>(
      (ref) => GenerateRecommendationUsecase(
        ref.read(dashboardHomeRepositoryProvider),
      ),
    );

final getDashboardDataUsecaseProvider = Provider<GetDashboardDataUsecase>((
  ref,
) {
  return GetDashboardDataUsecase(
    dashboardRepository: ref.read(dashboardRepositoryProvider),
  );
});

final readDashboardStateUsecaseProvider = Provider<ReadDashboardStateUsecase>((
  ref,
) {
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
  return shop_data.ShopRepositoryImpl(
    remoteDataSource: ref.read(shopRemoteDataSourceProvider),
    cache: ref.read(shopCacheServiceProvider),
  );
});

final shopUsecasesProvider = Provider<ShopUsecases>(
  (ref) => ShopUsecases(ref.read(shopRepositoryProvider)),
);

final shopRemoteDataSourceProvider = shop_remote.shopRemoteDataSourceProvider;

final silhouetteRepositoryProvider = Provider<ISilhouetteRepository>((ref) {
  return silhouette_data.SilhouetteRepositoryImpl(localDataSource: ref.read(silhouette_local.silhouetteLocalDataSourceProvider), remoteDataSource: ref.read(silhouette_remote.silhouetteRemoteDataSourceProvider));
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

// Review and style archive composition belongs here, at the application
// boundary, so presentation code depends only on domain contracts/use cases.
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepositoryImpl(
    remoteDataSource: ReviewRemoteDataSource(
      dio: ref.read(apiClientProvider).dio,
    ),
  );
});

final getReviewsByClotheUseCaseProvider = Provider<GetReviewsByClotheUseCase>(
  (ref) => GetReviewsByClotheUseCase(ref.read(reviewRepositoryProvider)),
);
final getMyReviewsUseCaseProvider = Provider<GetMyReviewsUseCase>(
  (ref) => GetMyReviewsUseCase(ref.read(reviewRepositoryProvider)),
);
final createReviewUseCaseProvider = Provider<CreateReviewUseCase>(
  (ref) => CreateReviewUseCase(ref.read(reviewRepositoryProvider)),
);
final updateReviewUseCaseProvider = Provider<UpdateReviewUseCase>(
  (ref) => UpdateReviewUseCase(ref.read(reviewRepositoryProvider)),
);
final deleteReviewUseCaseProvider = Provider<DeleteReviewUseCase>(
  (ref) => DeleteReviewUseCase(ref.read(reviewRepositoryProvider)),
);

final styleArchiveRepositoryProvider = Provider<IStyleArchiveRepository>(
  (ref) => ref.read(styleArchiveDataRepositoryProvider),
);

final styleArchiveDataRepositoryProvider = Provider<IStyleArchiveRepository>((
  ref,
) {
  return StyleArchiveRepositoryImpl(
    remoteDataSource: ref.read(styleArchiveRemoteDataSourceProvider),
  );
});

final saveStyleArchiveEntryUsecaseProvider =
    Provider<SaveStyleArchiveEntryUsecase>(
      (ref) => SaveStyleArchiveEntryUsecase(
        ref.read(styleArchiveRepositoryProvider),
      ),
    );

final getStyleArchiveUsecaseProvider = Provider<GetStyleArchiveUsecase>(
  (ref) => GetStyleArchiveUsecase(ref.read(styleArchiveRepositoryProvider)),
);
