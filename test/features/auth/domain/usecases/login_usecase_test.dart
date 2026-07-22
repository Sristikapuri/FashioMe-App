import 'package:dartz/dartz.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:fashio_me/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late LoginUsecase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = LoginUsecase(authRepository: mockAuthRepository);
  });

  test('should call login on repository with correct params', () async {
    const tAuthEntity = AuthEntity(
      firstName: 'Aria',
      lastName: 'Chen',
      username: 'aria',
      email: 'aria@example.com',
      password: 'secret123',
      gender: 'Female',
      age: '24',
    );

    when(
      () => mockAuthRepository.login('aria@example.com', 'secret123'),
    ).thenAnswer((_) async => const Right(tAuthEntity));

    final result = await usecase(
      const LoginUsecaseParams(
        email: 'aria@example.com',
        password: 'secret123',
      ),
    );

    expect(result.isRight(), isTrue);
    verify(
      () => mockAuthRepository.login('aria@example.com', 'secret123'),
    ).called(1);
  });
}
