import 'package:dartz/dartz.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late GetCurrentUserUsecase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = GetCurrentUserUsecase(authRepository: mockAuthRepository);
  });

  test('should call getCurrentUser on repository', () async {
    const tAuthEntity = AuthEntity(
      firstName: 'Aria',
      lastName: 'Chen',
      username: 'aria',
      email: 'aria@example.com',
      password: 'secret123',
      gender: 'Female',
      age: '24',
    );

    when(() => mockAuthRepository.getCurrentUser()).thenAnswer(
      (_) async => const Right(tAuthEntity),
    );

    final result = await usecase();

    expect(result.isRight(), isTrue);
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
  });
}
