import 'package:dartz/dartz.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:fashio_me/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late LogoutUsecase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = LogoutUsecase(authRepository: mockAuthRepository);
  });

  test('should call logout on repository', () async {
    when(
      () => mockAuthRepository.logout(),
    ).thenAnswer((_) async => const Right(true));

    final result = await usecase(const LogoutUsecaseParams());

    expect(result.isRight(), isTrue);
    verify(() => mockAuthRepository.logout()).called(1);
  });
}
