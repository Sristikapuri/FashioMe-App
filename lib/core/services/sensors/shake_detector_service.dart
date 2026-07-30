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



/// Call [start] to begin listening and [stop] to release the platform
/// sensor subscription (e.g. from a page's initState/dispose). The
/// broadcast [shakeStream] survives stop/start cycles; only [dispose]
/// (called automatically when the owning provider is torn down) closes
/// it for good.
class ShakeDetectorService {
  ShakeDetectorService({
    this.shakeThreshold = 22.0,
    this.cooldown = const Duration(milliseconds: 1500),
  });


  final double shakeThreshold;

  final Duration cooldown;

  final StreamController<void> _controller = StreamController<void>.broadcast();
  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastShakeAt;
  bool _isSupported = true;


  Stream<void> get shakeStream => _controller.stream;


  bool get isSupported => _isSupported;

  void start() {
    if (_subscription != null || _controller.isClosed) return;
    _subscription = accelerometerEventStream().listen(
      _onEvent,
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
  }

  void _onEvent(AccelerometerEvent event) {
    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    if (magnitude < shakeThreshold) return;

    final now = DateTime.now();
    if (_lastShakeAt != null && now.difference(_lastShakeAt!) < cooldown) {
      return;
    }
    _lastShakeAt = now;
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  /// [start] 
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
