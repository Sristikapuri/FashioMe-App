import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'requires onboarding when only the legacy completion flag exists',
    () async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final preferences = await SharedPreferences.getInstance();
      final service = UserSessionService(prefs: preferences);

      expect(service.hasCompletedOnboarding(), isFalse);
    },
  );

  test(
    'recognizes onboarding only after the current flow is completed',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = UserSessionService(prefs: preferences);

      await service.completeOnboarding();

      expect(service.hasCompletedOnboarding(), isTrue);
    },
  );

  group('profileImage persistence', () {
    test(
      'saveUser persists the profileImage so getCurrentUser returns it',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final service = UserSessionService(prefs: preferences);

        await service.saveUser(
          const SessionUser(
            userId: 'user-1',
            email: 'a@test.com',
            firstName: 'Aria',
            lastName: 'Chen',
            username: 'aria',
            profileImage: 'https://cdn.test/aria.png',
          ),
        );

        expect(
          service.getCurrentUser()?.profileImage,
          'https://cdn.test/aria.png',
        );
      },
    );

    test(
      'getCurrentUser returns a null profileImage when it was never set',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final service = UserSessionService(prefs: preferences);

        await service.saveUser(
          const SessionUser(
            userId: 'user-1',
            email: 'a@test.com',
            firstName: 'Aria',
            lastName: 'Chen',
            username: 'aria',
          ),
        );

        expect(service.getCurrentUser()?.profileImage, isNull);
      },
    );

    test(
      'saving an empty profileImage clears a previously stored one',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final service = UserSessionService(prefs: preferences);

        await service.saveUser(
          const SessionUser(
            userId: 'user-1',
            email: 'a@test.com',
            firstName: 'Aria',
            lastName: 'Chen',
            username: 'aria',
            profileImage: 'https://cdn.test/aria.png',
          ),
        );
        await service.saveUser(
          const SessionUser(
            userId: 'user-1',
            email: 'a@test.com',
            firstName: 'Aria',
            lastName: 'Chen',
            username: 'aria',
            profileImage: '',
          ),
        );

        expect(service.getCurrentUser()?.profileImage, isNull);
      },
    );

    test('a later saveUser overwrites an earlier profileImage', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = UserSessionService(prefs: preferences);

      await service.saveUser(
        const SessionUser(
          userId: 'user-1',
          email: 'a@test.com',
          firstName: 'Aria',
          lastName: 'Chen',
          username: 'aria',
          profileImage: 'https://cdn.test/old.png',
        ),
      );
      await service.saveUser(
        const SessionUser(
          userId: 'user-1',
          email: 'a@test.com',
          firstName: 'Aria',
          lastName: 'Chen',
          username: 'aria',
          profileImage: 'https://cdn.test/new.png',
        ),
      );

      expect(
        service.getCurrentUser()?.profileImage,
        'https://cdn.test/new.png',
      );
    });

    test('clearSession removes the stored profileImage', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = UserSessionService(prefs: preferences);

      await service.saveUser(
        const SessionUser(
          userId: 'user-1',
          email: 'a@test.com',
          firstName: 'Aria',
          lastName: 'Chen',
          username: 'aria',
          profileImage: 'https://cdn.test/aria.png',
        ),
      );
      await service.clearSession();
      await service.saveUser(
        const SessionUser(
          userId: 'user-1',
          email: 'a@test.com',
          firstName: 'Aria',
          lastName: 'Chen',
          username: 'aria',
        ),
      );

      expect(service.getCurrentUser()?.profileImage, isNull);
    });
  });
}
