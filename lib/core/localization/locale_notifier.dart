import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/core/providers/shared_prefs_provider.dart';

/// Locales the app ships translations for. Add new entries here and to
/// [AppStrings] (app_strings.dart) to support another language.
const supportedAppLocales = [Locale('en'), Locale('ne')];

const _prefsKey = 'app_locale_code';
const _languageSelectionVersionKey = 'language_selection_version';
const _currentLanguageSelectionVersion = 1;

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final savedCode = ref.read(sharedPreferencesProvider).getString(_prefsKey);
    final saved = supportedAppLocales.where((l) => l.languageCode == savedCode);
    return saved.isNotEmpty ? saved.first : const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedAppLocales.contains(locale)) return;
    state = locale;
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString(_prefsKey, locale.languageCode);
    await preferences.setInt(
      _languageSelectionVersionKey,
      _currentLanguageSelectionVersion,
    );
  }

  bool get isNepali => state.languageCode == 'ne';

  Future<void> toggle() =>
      setLocale(isNepali ? const Locale('en') : const Locale('ne'));

  /// False until the user has explicitly picked a language (as opposed to
  /// [state] just holding the English fallback). Used to show the one-time
  /// language picker before the first login/signup screen.
  bool get hasChosenLocale =>
      ref.read(sharedPreferencesProvider).getInt(_languageSelectionVersionKey) ==
          _currentLanguageSelectionVersion;
}
