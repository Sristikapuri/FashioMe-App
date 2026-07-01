import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/domain/usecases/login_usecase.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_providers.dart' as auth_providers;
import 'package:fashio_me/features/auth/presentation/providers/auth_view_model_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockLoginUsecase extends Mock implements LoginUsecase {}
class FakeLoginUsecaseParams extends Fake implements LoginUsecaseParams {}

void main() {
  late MockLoginUsecase mockLoginUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeLoginUsecaseParams());
  });

  setUp(() {
    mockLoginUsecase = MockLoginUsecase();
    container = ProviderContainer(
      overrides: [
        auth_providers.loginUsecaseProvider.overrideWithValue(mockLoginUsecase),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('LoginViewModel rejects invalid email before calling usecase', () async {
    when(() => mockLoginUsecase.call(any())).thenAnswer(
      (_) async => const Left(ApiFailure(message: 'invalid')),
    );

    final result = await container.read(loginViewModelProvider.notifier).login(
          email: 'bad-email',
          password: 'secret123',
        );

    expect(result, isFalse);
    expect(
      container.read(loginViewModelProvider).errorMessage,
      'Enter a valid email address.',
    );
    verifyNever(() => mockLoginUsecase.call(any()));
  });
}
