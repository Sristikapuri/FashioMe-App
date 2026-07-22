import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/logout_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/whoami_usecase.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_providers.dart'
    as auth_providers;
import 'package:fashio_me/features/auth/presentation/providers/auth_view_model_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockGetCurrentUserUsecase extends Mock implements GetCurrentUserUsecase {}

class MockLogoutUsecase extends Mock implements LogoutUsecase {}

class MockWhoamiUsecase extends Mock implements WhoamiUsecase {}

class MockUpdateProfileUsecase extends Mock implements UpdateProfileUsecase {}

void main() {
  late MockGetCurrentUserUsecase mockGetCurrentUserUsecase;
  late MockLogoutUsecase mockLogoutUsecase;
  late MockWhoamiUsecase mockWhoamiUsecase;
  late MockUpdateProfileUsecase mockUpdateProfileUsecase;
  late ProviderContainer container;

  setUp(() {
    mockGetCurrentUserUsecase = MockGetCurrentUserUsecase();
    mockLogoutUsecase = MockLogoutUsecase();
    mockWhoamiUsecase = MockWhoamiUsecase();
    mockUpdateProfileUsecase = MockUpdateProfileUsecase();

    container = ProviderContainer(
      overrides: [
        auth_providers.getCurrentUserUsecaseProvider.overrideWithValue(
          mockGetCurrentUserUsecase,
        ),
        auth_providers.logoutUsecaseProvider.overrideWithValue(
          mockLogoutUsecase,
        ),
        auth_providers.whoamiUsecaseProvider.overrideWithValue(
          mockWhoamiUsecase,
        ),
        auth_providers.updateProfileUsecaseProvider.overrideWithValue(
          mockUpdateProfileUsecase,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  final tAuthEntity = const AuthEntity(
    firstName: 'Aria',
    lastName: 'Chen',
    username: 'aria',
    email: 'aria@example.com',
  );

  test('AuthSessionViewModel stores the signed-in user in state', () {
    container.read(authSessionViewModelProvider.notifier).setUser(tAuthEntity);

    expect(container.read(authSessionViewModelProvider).user, tAuthEntity);
    expect(
      container.read(authSessionViewModelProvider).isAuthenticated,
      isTrue,
    );
  });
}
