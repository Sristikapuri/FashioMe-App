import 'package:dartz/dartz.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:fashio_me/features/auth/domain/usecases/register_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

class FakeAuthEntity extends Fake implements AuthEntity {}

void main() {
  late RegisterUsecase usecase;
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(FakeAuthEntity());
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = RegisterUsecase(authRepository: mockAuthRepository);
  });

  test('should call register on repository with correct params', () async {
    final tEntity = const AuthEntity(
      firstName: 'Aria',
      lastName: 'Chen',
      username: 'aria',
      email: 'aria@example.com',
      password: 'secret123',
      gender: 'Female',
      age: '24',
    );

    when(
      () => mockAuthRepository.register(any()),
    ).thenAnswer((_) async => Right(tEntity));

    final result = await usecase(
      const RegisterUsecaseParams(
        firstName: 'Aria',
        lastName: 'Chen',
        username: 'aria',
        email: 'aria@example.com',
        password: 'secret123',
        gender: 'Female',
        age: '24',
      ),
    );

    expect(result.isRight(), isTrue);
    verify(() => mockAuthRepository.register(any())).called(1);
  });
}
