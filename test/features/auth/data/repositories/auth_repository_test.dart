import 'package:dio/dio.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/data/datasources/auth_datasource.dart';
import 'package:fashio_me/features/auth/data/models/auth_model.dart';

import 'package:fashio_me/features/auth/data/repositories/auth_repository.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthDataSource extends Mock implements IAuthDataSource {}

AuthEntity _entity({
  String email = 'test@example.com',
  String password = 'password123',
}) {
  return AuthEntity(
    firstName: 'Aria',
    lastName: 'Stark',
    username: 'ariastark',
    email: email,
    password: password,
    gender: 'Female',
    age: '22',
  );
}

AuthModel _model({
  String authId = 'user_123',
  String email = 'test@example.com',
}) {
  return AuthModel(
    authId: authId,
    firstName: 'Aria',
    lastName: 'Stark',
    username: 'ariastark',
    email: email,
    password: 'password123',
    gender: 'Female',
    age: '22',
  );
}

void main() {
  late MockAuthDataSource remote;
  late MockAuthDataSource local;
  late AuthRepository repository;

  setUpAll(() {
    registerFallbackValue(_model());
  });

  setUp(() {
    remote = MockAuthDataSource();
    local = MockAuthDataSource();
    repository = AuthRepository(
      remoteDataSource: remote,
      localDataSource: local,
    );
  });

  group('AuthRepository Offline Registration Tests', () {
    test(
      'when remote throws connection DioException (no response / offline), falls back to local Hive registration',
      () async {
        final requestOptions = RequestOptions(path: '/auth/register');
        final connectionError = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
          error: 'Connection failed / No route to host',
          message: 'The connection errored: Connection failed',
        );

        when(() => remote.register(any())).thenThrow(connectionError);
        when(() => local.register(any())).thenAnswer((_) async => true);

        final result = await repository.register(_entity());

        expect(result.isRight(), isTrue);
        result.fold((l) => fail('Should not return left'), (r) {
          expect(r.email, 'test@example.com');
          expect(r.firstName, 'Aria');
        });

        verify(() => local.register(any())).called(1);
      },
    );

    test(
      'when remote responds with HTTP 400 Bad Request (e.g. Email already registered), returns ApiFailure',
      () async {
        final requestOptions = RequestOptions(path: '/auth/register');
        final serverResponseError = DioException(
          requestOptions: requestOptions,
          response: Response(
            requestOptions: requestOptions,
            statusCode: 400,
            data: {'message': 'Email already registered'},
          ),
        );

        when(() => remote.register(any())).thenThrow(serverResponseError);

        final result = await repository.register(_entity());

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<ApiFailure>());
          expect(failure.message, 'Email already registered');
        }, (_) => fail('Should not return right'));

        verifyNever(() => local.register(any()));
      },
    );
  });

  group('AuthRepository Offline Login Tests', () {
    test(
      'when remote throws connection DioException (offline) and local user exists, returns AuthEntity',
      () async {
        final requestOptions = RequestOptions(path: '/auth/login');
        final connectionError = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
          error: 'Connection failed',
        );

        when(
          () => remote.login('test@example.com', 'password123'),
        ).thenThrow(connectionError);
        when(
          () => local.login('test@example.com', 'password123'),
        ).thenAnswer((_) async => _model());

        final result = await repository.login(
          'test@example.com',
          'password123',
        );

        expect(result.isRight(), isTrue);
        result.fold((l) => fail('Should not fail'), (r) {
          expect(r.email, 'test@example.com');
        });
      },
    );

    test(
      'when remote throws connection DioException (offline) and local user does not exist, returns LocalDatabaseFailure',
      () async {
        final requestOptions = RequestOptions(path: '/auth/login');
        final connectionError = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
          error: 'Connection failed',
        );

        when(
          () => remote.login('test@example.com', 'password123'),
        ).thenThrow(connectionError);
        when(
          () => local.login('test@example.com', 'password123'),
        ).thenAnswer((_) async => null);

        final result = await repository.login(
          'test@example.com',
          'password123',
        );

        expect(result.isLeft(), isTrue);
        result.fold((failure) {
          expect(failure, isA<LocalDatabaseFailure>());
          expect(failure.message, contains('Account not found'));
        }, (_) => fail('Should not return right'));
      },
    );
  });
}
