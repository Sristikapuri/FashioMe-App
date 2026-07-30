import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/extensions/context_extensions.dart';
import 'package:fashio_me/core/services/biometric/biometric_auth_service.dart';
import 'package:fashio_me/features/auth/presentation/pages/login_page.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_session_providers.dart';

/// Gates access to [next] behind Face ID / fingerprint. Only shown when the
/// user has opted in via Settings > Face ID (BiometricSettingsNotifier) and
/// the app already holds a valid session — this is an app-lock layered on
/// top of the existing login, not a replacement for it. A user who can't or
/// doesn't want to use biometrics can always fall back to logging out and
/// signing back in with their password.
class BiometricLockPage extends ConsumerStatefulWidget {
  const BiometricLockPage({super.key, required this.next});

  final Widget next;

  @override
  ConsumerState<BiometricLockPage> createState() => _BiometricLockPageState();
}

class _BiometricLockPageState extends ConsumerState<BiometricLockPage> {
  bool _authenticating = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attempt());
  }

  Future<void> _attempt() async {
    if (_authenticating || !mounted) return;
    setState(() {
      _authenticating = true;
      _failed = false;
    });

    final strings = context.strings;
    final verified = await ref
        .read(biometricAuthServiceProvider)
        .authenticate(reason: strings.biometricPromptReason);

    if (!mounted) return;
    if (verified) {
      AppRoutes.pushReplacement(context, widget.next);
      return;
    }
    setState(() {
      _authenticating = false;
      _failed = true;
    });
  }

  Future<void> _useLogoutInstead() async {
    await ref.read(authSessionViewModelProvider.notifier).logout();
    if (!mounted) return;
    AppRoutes.pushReplacement(context, const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.fingerprint,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  strings.biometricLockTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  strings.biometricLockSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                if (_authenticating)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  )
                else ...[
                  if (_failed) ...[
                    Text(
                      strings.biometricLockFailed,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _attempt,
                      child: Text(strings.retry),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _useLogoutInstead,
                    child: Text(
                      strings.useLogoutInstead,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
