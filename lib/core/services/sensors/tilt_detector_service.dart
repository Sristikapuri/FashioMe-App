import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum TiltDirection { left, right }

final tiltDetectorServiceProvider = Provider<TiltDetectorService>((ref) {
  final service = TiltDetectorService();
  ref.onDispose(service.dispose);
  return service;
});



/// Call [start] to begin listening and [stop] to release the platform
/// sensor subscription (e.g. from a page's initState/dispose). The
/// broadcast [tiltStream] survives stop/start cycles; only [dispose]
/// (called automatically when the owning provider is torn down) closes
/// it for good.
class TiltDetectorService {
  TiltDetectorService({
    this.rotationThreshold = 2.5,
    this.cooldown = const Duration(milliseconds: 900),
  });


  final double rotationThreshold;

  final Duration cooldown;

  final StreamController<TiltDirection> _controller =
      StreamController<TiltDirection>.broadcast();
  StreamSubscription<GyroscopeEvent>? _subscription;
  DateTime? _lastTiltAt;
  bool _isSupported = true;

  /// Emits [TiltDirection.left] or [TiltDirection.right] once per
  /// deliberate tilt gesture.
  Stream<TiltDirection> get tiltStream => _controller.stream;

  /// False once the platform has reported it has no gyroscope.
  bool get isSupported => _isSupported;

  void start() {
    if (_subscription != null || _controller.isClosed) return;
    _subscription = gyroscopeEventStream().listen(
      _onEvent,
      onError: (Object error, StackTrace _) {

        _isSupported = false;
        _subscription?.cancel();
        _subscription = null;
        if (kDebugMode) {
          debugPrint('TiltDetectorService: gyroscope unavailable ($error)');
        }
      },
      cancelOnError: true,
    );
  }

  void _onEvent(GyroscopeEvent event) {

    if (event.y.abs() < rotationThreshold) return;

    final now = DateTime.now();
    if (_lastTiltAt != null && now.difference(_lastTiltAt!) < cooldown) {
      return;
    }
    _lastTiltAt = now;

    final direction = event.y > 0 ? TiltDirection.left : TiltDirection.right;
    if (!_controller.isClosed) {
      _controller.add(direction);
    }
  }

  /// [start] can be called again later to resume.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
