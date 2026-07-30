import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/core/providers/shared_prefs_provider.dart';

const sensorGesturesEnabledKey = 'sensor_gestures_enabled';

final sensorGesturesEnabledProvider = NotifierProvider<SensorGesturesNotifier, bool>(
  SensorGesturesNotifier.new,
);

class SensorGesturesNotifier extends Notifier<bool> {
  @override
  bool build() => ref
      .read(sharedPreferencesProvider)
      .getBool(sensorGesturesEnabledKey) ?? false;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(sensorGesturesEnabledKey, enabled);
  }
}
