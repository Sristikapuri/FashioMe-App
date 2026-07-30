import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  ref.onDispose(service.dispose);
  return service;
});

/// Wraps [AppLinks] 


/// Call [start] to begin listening and [stop] to release the platform
/// subscription (e.g. only while a payment dialog is open). The broadcast
/// [linkStream] survives stop/start cycles; only [dispose] (called

class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();
  StreamSubscription<Uri>? _subscription;
  bool _isSupported = true;


  Stream<Uri> get linkStream => _controller.stream;

  bool get isSupported => _isSupported;

  void start() {
    if (_subscription != null || _controller.isClosed) return;

    _appLinks
        .getInitialLink()
        .then((uri) {
          if (uri != null && !_controller.isClosed) {
            _controller.add(uri);
          }
        })
        .catchError((Object error, StackTrace _) {
          if (kDebugMode) {
            debugPrint('DeepLinkService: initial link unavailable ($error)');
          }
        });

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (!_controller.isClosed) {
          _controller.add(uri);
        }
      },
      onError: (Object error, StackTrace _) {
        // Some platforms/build configs don't support deep links at all.
        // Fail closed instead of crashing the app.
        _isSupported = false;
        _subscription?.cancel();
        _subscription = null;
        if (kDebugMode) {
          debugPrint('DeepLinkService: link stream unavailable ($error)');
        }
      },
      cancelOnError: true,
    );
  }

  /// Cancels the platform link subscription. Safe to call repeatedly;
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
