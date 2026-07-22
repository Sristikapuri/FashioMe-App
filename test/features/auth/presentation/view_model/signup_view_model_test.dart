import 'package:dartz/dartz.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/usecases/register_usecase.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_providers.dart'
    as auth_providers;
import 'package:fashio_me/features/auth/presentation/providers/auth_view_model_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockRegisterUsecase extends Mock implements RegisterUsecase {}

class FakeRegisterUsecaseParams extends Fake implements RegisterUsecaseParams {}

void main() {
  late MockRegisterUsecase mockRegisterUsecase;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeRegisterUsecaseParams());
  });

  setUp(() {
    mockRegisterUsecase = MockRegisterUsecase();
    container = ProviderContainer(
      overrides: [
        auth_providers.registerUsecaseProvider.overrideWithValue(
          mockRegisterUsecase,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('SignupViewModel rejects password mismatch', () async {
    when(() => mockRegisterUsecase.call(any())).thenAnswer(
      (_) async => const Right(
        AuthEntity(
          firstName: 'Aria',
          lastName: 'Chen',
          username: 'aria',
          email: 'aria@example.com',
          password: 'secret123',
          gender: 'Female',
          age: '24',
        ),
      ),
    );

    final result = await container
        .read(signupViewModelProvider.notifier)
        .register(
          firstName: 'Aria',
          lastName: 'Chen',
          username: 'aria',
          email: 'aria@example.com',
          password: 'secret123',
          confirmPassword: 'secret999',
          gender: 'Female',
          age: '24',
        );

    expect(result, isFalse);
    expect(
      container.read(signupViewModelProvider).errorMessage,
      'Passwords do not match.',
    );
    verifyNever(() => mockRegisterUsecase.call(any()));
  });
}
