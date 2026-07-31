import 'package:fashio_me/core/localization/locale_notifier.dart';
import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('requires language selection when only a legacy locale code exists', () async {
    SharedPreferences.setMockInitialValues({'app_locale_code': 'en'});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(localeProvider.notifier).hasChosenLocale,
      isFalse,
    );
  });

  test('records language selection after the user chooses a language', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    await container.read(localeProvider.notifier).setLocale(const Locale('ne'));

    expect(container.read(localeProvider.notifier).hasChosenLocale, isTrue);
    expect(container.read(localeProvider).languageCode, 'ne');
  });
}
