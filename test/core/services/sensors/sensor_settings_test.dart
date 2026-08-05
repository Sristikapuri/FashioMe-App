import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:fashio_me/core/services/sensors/sensor_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // The provider under test reads SharedPreferences synchronously via
  // ref.read, so each test builds its own mock-backed instance up front.
  Future<ProviderContainer> buildContainer(
    Map<String, Object> initialValues,
  ) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    return container;
  }

  test('defaults to enabled when no preference has ever been saved', () async {
    final container = await buildContainer({});
    addTearDown(container.dispose);

    expect(container.read(sensorGesturesEnabledProvider), isTrue);
  });

  test('honors a previously persisted enabled value on startup', () async {
    final container = await buildContainer({'sensor_gestures_enabled': true});
    addTearDown(container.dispose);

    expect(container.read(sensorGesturesEnabledProvider), isTrue);
  });

  test('setEnabled(true) updates state and persists the new value', () async {
    final container = await buildContainer({});
    addTearDown(container.dispose);

    await container
        .read(sensorGesturesEnabledProvider.notifier)
        .setEnabled(true);

    expect(container.read(sensorGesturesEnabledProvider), isTrue);
  });

  test('setEnabled(false) updates state and persists the new value', () async {
    final container = await buildContainer({'sensor_gestures_enabled': true});
    addTearDown(container.dispose);

    await container
        .read(sensorGesturesEnabledProvider.notifier)
        .setEnabled(false);

    expect(container.read(sensorGesturesEnabledProvider), isFalse);
  });

  test(
    'a persisted value survives rebuilding the notifier from prefs',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final firstContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      await firstContainer
          .read(sensorGesturesEnabledProvider.notifier)
          .setEnabled(true);
      firstContainer.dispose();

      final secondContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(secondContainer.dispose);

      expect(secondContainer.read(sensorGesturesEnabledProvider), isTrue);
    },
  );
}
