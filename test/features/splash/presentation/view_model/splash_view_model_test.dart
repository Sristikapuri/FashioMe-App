import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/entities/uploaded_file.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_initial_route_usecase.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_providers.dart'
    as auth_providers;
import 'package:fashio_me/features/splash/presentation/providers/splash_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class FakeAuthRepository implements IAuthRepository {
  int routeCalls = 0;

  @override
  Future<Either<Failure, String>> getInitialRoute() async {
    routeCalls++;
    return const Right('dashboard');
  }

  @override
  Future<Either<Failure, AuthEntity>> register(AuthEntity entity) =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, AuthEntity>> login(String email, String password) =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, AuthEntity>> whoami() => throw UnimplementedError();
  @override
  Future<Either<Failure, AuthEntity>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? gender,
    int? age,
    UploadedFile? profileImage,
    String? password,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, bool>> logout() => throw UnimplementedError();
  @override
  Future<Either<Failure, bool>> isEmailExists(String email) =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, bool>> completeOnboarding() =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, bool>> hasCompletedOnboarding() =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, bool>> isLoggedIn() => throw UnimplementedError();
  @override
  Future<Either<Failure, bool>> forgotPassword(String email) =>
      throw UnimplementedError();
  @override
  Future<Either<Failure, bool>> resetPassword({
    required String email,
    required String token,
    required String password,
  }) => throw UnimplementedError();
  @override
  Future<Either<Failure, bool>> deleteAccount() => throw UnimplementedError();
}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late ProviderContainer container;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [
        auth_providers.getInitialRouteUsecaseProvider.overrideWithValue(
          GetInitialRouteUsecase(authRepository: fakeAuthRepository),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('SplashViewModel resolves route from usecase', () async {
    await container
        .read(splashViewModelProvider.notifier)
        .resolveInitialRoute();

    expect(container.read(splashViewModelProvider).targetRoute, 'dashboard');
    expect(container.read(splashViewModelProvider).isResolvingRoute, isFalse);
    expect(fakeAuthRepository.routeCalls, 1);
  });
}
