import 'package:dartz/dartz.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_initial_route_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}

void main() {
  late GetInitialRouteUsecase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = GetInitialRouteUsecase(authRepository: mockAuthRepository);
  });

  test('should call getInitialRoute on repository', () async {
    when(
      () => mockAuthRepository.getInitialRoute(),
    ).thenAnswer((_) async => const Right('dashboard'));

    final result = await usecase();

    expect(result.isRight(), isTrue);
    verify(() => mockAuthRepository.getInitialRoute()).called(1);
  });
}
