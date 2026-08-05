import 'dart:async';
import 'dart:io';

import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the runtime-discovered (or configured) backend base URL.
/// On Android this is set once during splash via TCP/UDP discovery.
/// On other platforms it stays null and [ApiEndpoints] falls back to localhost.
class ApiConfig {
  ApiConfig._();

  static String? _overrideBaseUrl;

  /// Call this to override the base URL for Android at runtime.
  static void setBaseUrl(String url) {
    _overrideBaseUrl = url;
    debugPrint('[ApiConfig] Base URL set to: $url');
  }

  static String? get overrideBaseUrl => _overrideBaseUrl;
}

// ─── SharedPreferences key ───────────────────────────────────────────────────
const _kCachedIp = 'fashiome_backend_ip';
const _kFallbackIp = '192.168.1.200'; // last-resort hardcoded fallback
const _kPort = 8089;
const _kDiscoveryPort = 9988; // UDP discovery port on the backend
const _kDiscoveryMessage = 'FASHIOME_DISCOVER';
const _kDiscoveryPrefix = 'FASHIOME_SERVER:';

/// Discovers the backend IP via fast TCP socket probe + UDP broadcast.
///
/// Call this ONCE from the splash page on Android before any API call.
final backendDiscoveryServiceProvider = Provider<BackendDiscoveryService>(
  (ref) => BackendDiscoveryService(prefs: ref.read(sharedPreferencesProvider)),
);

class BackendDiscoveryService {
  BackendDiscoveryService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  /// Returns the full base URL, e.g. "http://192.168.1.200:8089/api/v1"
  Future<String> resolveBackendUrl() async {
    // Not Android → use localhost
    if (!Platform.isAndroid) {
      return 'http://localhost:$_kPort/api/v1';
    }

    // 1. Fast TCP probe to candidate IPs (takes < 300ms)
    try {
      final probedIp = await _probeCandidates();
      if (probedIp != null) {
        await _prefs.setString(_kCachedIp, probedIp);
        final url = 'http://$probedIp:$_kPort/api/v1';
        debugPrint('[Discovery] Resolved via TCP probe: $url');
        return url;
      }
    } catch (e) {
      debugPrint('[Discovery] TCP probe failed: $e');
    }

    // 2. UDP broadcast discovery (1.5s timeout fallback)
    try {
      final ip = await _udpDiscover();
      if (ip != null && ip.isNotEmpty) {
        await _prefs.setString(_kCachedIp, ip);
        final url = 'http://$ip:$_kPort/api/v1';
        debugPrint('[Discovery] Found via UDP: $url');
        return url;
      }
    } catch (e) {
      debugPrint('[Discovery] UDP failed: $e');
    }

    // 3. Cached IP from last successful session
    final cached = _prefs.getString(_kCachedIp);
    if (cached != null && cached.isNotEmpty) {
      final url = 'http://$cached:$_kPort/api/v1';
      debugPrint('[Discovery] Using cached IP: $url');
      return url;
    }

    // 4. Hardcoded fallback IP
    const url = 'http://$_kFallbackIp:$_kPort/api/v1';
    debugPrint('[Discovery] Using fallback IP: $url');
    return url;
  }

  /// Fast TCP socket probe on candidate IP addresses in parallel (<100ms).
  Future<String?> _probeCandidates() async {
    final candidateSet = <String>{};

    // 1. Cached IP if previously discovered
    final cached = _prefs.getString(_kCachedIp);
    if (cached != null && cached.isNotEmpty) {
      candidateSet.add(cached);
    }

    // 2. Known static host & bridge IPs
    candidateSet.addAll([
      '192.168.0.15',
      '192.168.1.200',
      '10.0.2.2',     // Android Emulator alias
      '192.168.3.1',
      '192.168.2.1',
      '192.168.1.1',
      '192.168.0.1',
    ]);

    // 3. Dynamically discover device's own IPv4 network subnet(s)
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
              // Add gateway and common host IPs on the same subnet
              candidateSet.add('$prefix.1');
              candidateSet.add('$prefix.15');
              candidateSet.add('$prefix.100');
              candidateSet.add('$prefix.200');
            }
          }
        }
      }
    } catch (_) {}

    // Run probes in parallel with a fast 300ms timeout
    final futures = candidateSet.map((ip) async {
      try {
        final socket = await Socket.connect(
          ip,
          _kPort,
          timeout: const Duration(milliseconds: 300),
        );
        socket.destroy();
        return ip;
      } catch (_) {
        return null;
      }
    });

    final results = await Future.wait(futures);
    for (final ip in results) {
      if (ip != null) return ip;
    }
    return null;
  }


  Future<String?> _udpDiscover() async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      ).timeout(const Duration(seconds: 1));
      socket.broadcastEnabled = true;

      final msg = _kDiscoveryMessage.codeUnits;

      for (final addr in await _broadcastAddresses()) {
        socket.send(msg, InternetAddress(addr), _kDiscoveryPort);
      }
      socket.send(
        msg,
        InternetAddress('255.255.255.255'),
        _kDiscoveryPort,
      );

      final completer = Completer<String?>();
      final timer = Timer(const Duration(milliseconds: 1500), () {
        if (!completer.isCompleted) completer.complete(null);
      });

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket?.receive();
          if (datagram != null) {
            final response = String.fromCharCodes(datagram.data).trim();
            if (response.startsWith(_kDiscoveryPrefix)) {
              final ip = response.substring(_kDiscoveryPrefix.length).split(':').first;
              timer.cancel();
              if (!completer.isCompleted) completer.complete(ip);
            }
          }
        }
      });

      return await completer.future;
    } finally {
      socket?.close();
    }
  }

  static Future<List<String>> _broadcastAddresses() async {
    final result = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              result.add('${parts[0]}.${parts[1]}.${parts[2]}.255');
            }
          }
        }
      }
    } catch (_) {}
    return result;
  }
}
