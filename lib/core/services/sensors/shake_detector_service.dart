import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

final shakeDetectorServiceProvider = Provider<ShakeDetectorService>((ref) {
  final service = ShakeDetectorService();
  ref.onDispose(service.dispose);
  return service;
});

/// Listens to device accelerometer events to detect shake gestures.
///
/// Uses [userAccelerometerEventStream] (which filters out gravity baseline)
/// for high accuracy, falling back to [accelerometerEventStream] if needed.
class ShakeDetectorService {
  ShakeDetectorService({
    this.userShakeThreshold = 3.2,
    this.fallbackShakeThreshold = 12.0,
    this.cooldown = const Duration(milliseconds: 1200),
  });

  /// Acceleration threshold for userAccelerometer (without gravity).
  final double userShakeThreshold;

  /// Acceleration threshold for raw accelerometer (including gravity).
  final double fallbackShakeThreshold;

  final Duration cooldown;

  final StreamController<void> _controller = StreamController<void>.broadcast();
  StreamSubscription<dynamic>? _subscription;
  DateTime? _lastShakeAt;
  bool _isSupported = true;

  Stream<void> get shakeStream => _controller.stream;

  bool get isSupported => _isSupported;

  void start() {
    if (_subscription != null || _controller.isClosed) return;

    try {
      _subscription = userAccelerometerEventStream().listen(
        _onUserEvent,
        onError: (Object error, StackTrace _) {
          if (kDebugMode) {
            debugPrint('ShakeDetectorService: userAccelerometer error, falling back ($error)');
          }
          _startFallbackStream();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _startFallbackStream();
    }
  }

  void _startFallbackStream() {
    _subscription?.cancel();
    try {
      _subscription = accelerometerEventStream().listen(
        _onFallbackEvent,
        onError: (Object error, StackTrace _) {
          _isSupported = false;
          _subscription?.cancel();
          _subscription = null;
          if (kDebugMode) {
            debugPrint('ShakeDetectorService: accelerometer unavailable ($error)');
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      _isSupported = false;
      _subscription = null;
    }
  }

  void _onUserEvent(UserAccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude < userShakeThreshold) return;
    _triggerShake();
  }

  void _onFallbackEvent(AccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude < fallbackShakeThreshold) return;
    _triggerShake();
  }

  void _triggerShake() {
    final now = DateTime.now();
    if (_lastShakeAt != null && now.difference(_lastShakeAt!) < cooldown) {
      return;
    }
    _lastShakeAt = now;
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
