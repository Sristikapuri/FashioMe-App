import 'package:dartz/dartz.dart';
import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/upload_item_photo_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/get_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/save_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/presentation/providers/silhouette_flow_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSilhouetteProfileUsecase extends Mock
    implements GetSilhouetteProfileUsecase {}

class MockSaveSilhouetteProfileUsecase extends Mock
    implements SaveSilhouetteProfileUsecase {}

class MockUploadItemPhotoUsecase extends Mock
    implements UploadItemPhotoUsecase {}

void main() {
  late MockGetSilhouetteProfileUsecase mockGetProfile;
  late MockSaveSilhouetteProfileUsecase mockSaveProfile;
  late MockUploadItemPhotoUsecase mockUploadPhoto;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      const SaveSilhouetteProfileParams(
        profile: SilhouetteProfile(
          gender: 'female',
          heightCm: 170,
          weightKg: 60,
          buildType: 'athletic',
          bodyShape: 'curvy',
          skinTone: 'warm',
        ),
      ),
    );
  });

  setUp(() {
    mockGetProfile = MockGetSilhouetteProfileUsecase();
    mockSaveProfile = MockSaveSilhouetteProfileUsecase();
    mockUploadPhoto = MockUploadItemPhotoUsecase();

    when(() => mockGetProfile()).thenAnswer((_) async => const Right(null));

    container = ProviderContainer(
      overrides: [
        getSilhouetteProfileUsecaseProvider.overrideWithValue(mockGetProfile),
        saveSilhouetteProfileUsecaseProvider.overrideWithValue(mockSaveProfile),
        uploadItemPhotoUsecaseProvider.overrideWithValue(mockUploadPhoto),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state has step 0 and default values', () {
    final state = container.read(silhouetteFlowViewModelProvider);
    expect(state.currentStep, 0);
    expect(state.gender, 'female');
  });

  test('nextStep and previousStep navigate steps properly', () {
    final notifier = container.read(silhouetteFlowViewModelProvider.notifier);
    notifier.nextStep();
    expect(container.read(silhouetteFlowViewModelProvider).currentStep, 1);

    notifier.previousStep();
    expect(container.read(silhouetteFlowViewModelProvider).currentStep, 0);
  });

  test('saveProfile returns 0 on local fallback success', () async {
    when(
      () => mockSaveProfile(any()),
    ).thenAnswer((_) async => const Right(false));

    final notifier = container.read(silhouetteFlowViewModelProvider.notifier);
    notifier.selectFaceShape('oval'); // Complete step 3 requirement

    final result = await notifier.saveProfile();
    expect(result, 0);
  });

  test('saveProfile returns 1 on backend confirmed success', () async {
    when(
      () => mockSaveProfile(any()),
    ).thenAnswer((_) async => const Right(true));

    final notifier = container.read(silhouetteFlowViewModelProvider.notifier);
    notifier.selectFaceShape('oval');

    final result = await notifier.saveProfile();
    expect(result, 1);
  });

  test('saveProfile returns -1 on save failure', () async {
    when(() => mockSaveProfile(any())).thenAnswer(
      (_) async => const Left(LocalDatabaseFailure(message: 'Error')),
    );

    final notifier = container.read(silhouetteFlowViewModelProvider.notifier);
    notifier.selectFaceShape('oval');

    final result = await notifier.saveProfile();
    expect(result, -1);
  });
}
