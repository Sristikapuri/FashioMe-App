import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:fashio_me/features/silhouette/data/datasources/local/silhouette_local_datasource.dart';
import 'package:fashio_me/features/silhouette/data/models/silhouette_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserSessionService extends Mock implements UserSessionService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SilhouetteLocalDataSource dataSource;
  late MockUserSessionService mockSessionService;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockSessionService = MockUserSessionService();
    mockPrefs = MockSharedPreferences();
    dataSource = SilhouetteLocalDataSource(
      prefs: mockPrefs,
      userSessionService: mockSessionService,
    );
  });

  const testModel = SilhouetteProfileModel(
    gender: 'female',
    heightCm: 170,
    weightKg: 60,
    buildType: 'athletic',
    bodyShape: 'curvy',
    skinTone: 'warm',
    faceShape: 'oval',
  );

  test('saves profile using guest key when user is not logged in', () async {
    when(() => mockSessionService.getUserId()).thenReturn(null);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

    await dataSource.saveProfile(testModel);

    verify(
      () => mockPrefs.setString('silhouette_profile_guest', any()),
    ).called(1);
  });

  test('saves profile using user key when user is logged in', () async {
    when(() => mockSessionService.getUserId()).thenReturn('user_123');
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

    await dataSource.saveProfile(testModel);

    verify(
      () => mockPrefs.setString('silhouette_profile_user_123', any()),
    ).called(1);
  });
}
