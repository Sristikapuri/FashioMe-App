import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('requires onboarding when only the legacy completion flag exists', () async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    final preferences = await SharedPreferences.getInstance();
    final service = UserSessionService(prefs: preferences);

    expect(service.hasCompletedOnboarding(), isFalse);
  });

  test('recognizes onboarding only after the current flow is completed', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = UserSessionService(prefs: preferences);

    await service.completeOnboarding();

    expect(service.hasCompletedOnboarding(), isTrue);
  });
}
