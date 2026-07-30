import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

/// Thin wrapper around [LocalAuthentication] (Face ID / fingerprint / device
/// PIN as a fallback). Every method fails closed — returns false instead of
/// throwing — so a device with no biometric hardware, no enrolled face, or a
/// user who cancels never crashes the app.
class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  Future<bool> isSupported() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('BiometricAuthService: support check failed ($error)');
      }
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (error) {
     
      if (kDebugMode) {
        debugPrint(
          'BiometricAuthService: authenticate failed (${error.code}: ${error.message})',
        );
      }
      return false;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('BiometricAuthService: unexpected error ($error)');
      }
      return false;
    }
  }
}
