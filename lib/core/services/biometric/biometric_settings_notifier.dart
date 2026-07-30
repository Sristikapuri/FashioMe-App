import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/core/providers/shared_prefs_provider.dart';

const _prefsKey = 'biometric_lock_enabled';

final biometricSettingsProvider =
    NotifierProvider<BiometricSettingsNotifier, bool>(
      BiometricSettingsNotifier.new,
    );


class BiometricSettingsNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(_prefsKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_prefsKey, enabled);
  }
}
