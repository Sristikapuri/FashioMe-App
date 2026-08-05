import 'package:dio/dio.dart';
import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/core/services/storage/token_service.dart';
import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:fashio_me/features/auth/data/datasources/remote/auth_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockUserSessionService extends Mock implements UserSessionService {}

class MockTokenService extends Mock implements TokenService {}

class FakeOptions extends Fake implements Options {}

class FakeSessionUser extends Fake implements SessionUser {}

Response<dynamic> _response(Map<String, dynamic> data) {
  return Response<dynamic>(
    data: data,
    requestOptions: RequestOptions(path: ''),
  );
}

void main() {
  late MockApiClient apiClient;
  late MockUserSessionService userSessionService;
  late MockTokenService tokenService;
  late AuthRemoteDatasource datasource;

  setUpAll(() {
    registerFallbackValue(FakeOptions());
    registerFallbackValue(FakeSessionUser());
  });

  setUp(() {
    apiClient = MockApiClient();
    userSessionService = MockUserSessionService();
    tokenService = MockTokenService();
    datasource = AuthRemoteDatasource(
      apiClient: apiClient,
      userSessionService: userSessionService,
      tokenService: tokenService,
    );
    when(() => userSessionService.saveUser(any())).thenAnswer((_) async {});
    when(() => tokenService.saveToken(any())).thenAnswer((_) async {});
  });

  group('login', () {
    test('saves the returned profileImage into the local session', () async {
      when(
        () => apiClient.post(ApiEndpoints.authLogin, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response({
          'isSuccess': true,
          'responseData': {
            'user': {
              '_id': 'user-1',
              'email': 'a@test.com',
              'firstName': 'Aria',
              'lastName': 'Chen',
              'username': 'aria',
              'profileImage': 'https://cdn.test/aria.png',
            },
            'token': 'tok-123',
          },
        }),
      );

      await datasource.login('a@test.com', 'secret123');

      final captured =
          verify(
                () => userSessionService.saveUser(captureAny()),
              ).captured.single
              as SessionUser;
      expect(captured.profileImage, 'https://cdn.test/aria.png');
    });

    test('returns a model carrying the fresh profileImage', () async {
      when(
        () => apiClient.post(ApiEndpoints.authLogin, data: any(named: 'data')),
      ).thenAnswer(
        (_) async => _response({
          'isSuccess': true,
          'responseData': {
            'user': {
              '_id': 'user-1',
              'email': 'a@test.com',
              'firstName': 'Aria',
              'lastName': 'Chen',
              'username': 'aria',
              'profileImage': 'https://cdn.test/aria.png',
            },
          },
        }),
      );

      final user = await datasource.login('a@test.com', 'secret123');

      expect(user?.profileImage, 'https://cdn.test/aria.png');
    });

    test(
      'does not persist a session when the response has no authId',
      () async {
        when(
          () =>
              apiClient.post(ApiEndpoints.authLogin, data: any(named: 'data')),
        ).thenAnswer(
          (_) async => _response({
            'isSuccess': true,
            'responseData': {
              'user': {'email': 'a@test.com', 'firstName': 'Aria'},
            },
          }),
        );

        await datasource.login('a@test.com', 'secret123');

        verifyNever(() => userSessionService.saveUser(any()));
      },
    );
  });

  group('whoami', () {
    test(
      'returns null without calling the API when no token is stored',
      () async {
        when(() => tokenService.getToken()).thenAnswer((_) async => null);

        final result = await datasource.whoami();

        expect(result, isNull);
        verifyNever(() => apiClient.get(any(), options: any(named: 'options')));
      },
    );

    test('saves and returns the profileImage from a fresh session', () async {
      when(() => tokenService.getToken()).thenAnswer((_) async => 'tok-123');
      when(
        () => apiClient.get(
          ApiEndpoints.authWhoami,
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => _response({
          'isSuccess': true,
          'responseData': {
            '_id': 'user-1',
            'email': 'a@test.com',
            'firstName': 'Aria',
            'lastName': 'Chen',
            'username': 'aria',
            'profileImage': 'https://cdn.test/fresh.png',
          },
        }),
      );

      final result = await datasource.whoami();

      expect(result?.profileImage, 'https://cdn.test/fresh.png');
      final captured =
          verify(
                () => userSessionService.saveUser(captureAny()),
              ).captured.single
              as SessionUser;
      expect(captured.profileImage, 'https://cdn.test/fresh.png');
    });
  });

  group('updateProfile', () {
    test(
      'returns null without calling the API when no token is stored',
      () async {
        when(() => tokenService.getToken()).thenAnswer((_) async => null);

        final result = await datasource.updateProfile(firstName: 'Aria');

        expect(result, isNull);
        verifyNever(
          () => apiClient.put(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        );
      },
    );

    test(
      'propagates the newly uploaded profileImage into the session and result',
      () async {
        when(() => tokenService.getToken()).thenAnswer((_) async => 'tok-123');
        when(
          () => apiClient.put(
            ApiEndpoints.authUpdate,
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => _response({
            'isSuccess': true,
            'responseData': {
              '_id': 'user-1',
              'email': 'a@test.com',
              'firstName': 'Aria',
              'lastName': 'Chen',
              'username': 'aria',
              'profileImage': 'https://cdn.test/new-upload.png',
            },
          }),
        );

        final result = await datasource.updateProfile(firstName: 'Aria');

        expect(result?.profileImage, 'https://cdn.test/new-upload.png');
        final captured =
            verify(
                  () => userSessionService.saveUser(captureAny()),
                ).captured.single
                as SessionUser;
        expect(captured.profileImage, 'https://cdn.test/new-upload.png');
      },
    );

    test('returns null when the backend reports failure', () async {
      when(() => tokenService.getToken()).thenAnswer((_) async => 'tok-123');
      when(
        () => apiClient.put(
          ApiEndpoints.authUpdate,
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => _response({'isSuccess': false, 'responseData': null}),
      );

      final result = await datasource.updateProfile(firstName: 'Aria');

      expect(result, isNull);
      verifyNever(() => userSessionService.saveUser(any()));
    });
  });

  group('getCurrentUser', () {
    test('returns the profileImage stored in the local session', () async {
      when(() => userSessionService.getCurrentUser()).thenReturn(
        const SessionUser(
          userId: 'user-1',
          email: 'a@test.com',
          firstName: 'Aria',
          lastName: 'Chen',
          username: 'aria',
          profileImage: 'https://cdn.test/cached.png',
        ),
      );

      final result = await datasource.getCurrentUser();

      expect(result?.profileImage, 'https://cdn.test/cached.png');
    });

    test('returns null when there is no cached session', () async {
      when(() => userSessionService.getCurrentUser()).thenReturn(null);

      final result = await datasource.getCurrentUser();

      expect(result, isNull);
    });
  });
}
