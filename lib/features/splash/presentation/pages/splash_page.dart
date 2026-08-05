import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:fashio_me/core/services/biometric/biometric_auth_service.dart';
import 'package:fashio_me/core/services/biometric/biometric_settings_notifier.dart';
import 'package:fashio_me/core/services/network/backend_discovery_service.dart';
import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:fashio_me/features/biometric_lock/presentation/pages/biometric_lock_page.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fashio_me/features/language_selection/presentation/pages/language_selection_page.dart';
import 'package:fashio_me/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:fashio_me/features/silhouette/presentation/pages/silhouette_flow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Run UDP backend discovery in parallel with the 2-second animation.
    // Results are applied before navigation so the first API call already
    // uses the correct server IP.
    _runDiscovery();

    // Navigate after splash animation completes (2 seconds)
    Timer(const Duration(seconds: 2), _navigate);
  }

  Future<void> _runDiscovery() async {
    try {
      final discovery = ref.read(backendDiscoveryServiceProvider);
      final url = await discovery.resolveBackendUrl();
      ApiConfig.setBaseUrl(url);
      // Also update the live Dio client so any in-flight requests use the new URL
      ref.read(apiClientProvider).updateBaseUrl(url);
    } catch (e) {
      debugPrint('[Splash] Discovery error (non-fatal): $e');
    }
  }

  Future<void> _navigate() async {
    // Prevent double-navigation
    if (_navigated || !mounted) return;
    _navigated = true;

    Widget targetPage;

    try {
      // Read session directly from SharedPreferences – no network calls
      final prefs = ref.read(sharedPreferencesProvider);
      final session = UserSessionService(prefs: prefs);

      final isLoggedIn = session.isLoggedIn();

      if (isLoggedIn) {
        // Returning user: try to verify token quickly (3s cap)
        Widget dashboardOrSilhouette = const DashboardPage();
        try {
          final hasCompletedResult = await ref
              .read(hasCompletedSilhouetteProfileUsecaseProvider)()
              .timeout(const Duration(seconds: 3));
          final done = hasCompletedResult.fold((_) => false, (v) => v);
          dashboardOrSilhouette =
              done ? const DashboardPage() : const SilhouetteFlowPage();
        } catch (_) {
          dashboardOrSilhouette = const DashboardPage();
        }

        targetPage = dashboardOrSilhouette;

        // Biometric lock for returning logged-in users
        if (targetPage is DashboardPage && ref.read(biometricSettingsProvider)) {
          try {
            final supported = await ref
                .read(biometricAuthServiceProvider)
                .isSupported()
                .timeout(const Duration(seconds: 2));
            if (supported) {
              targetPage = BiometricLockPage(next: targetPage);
            }
          } catch (_) {}
        }
      } else {
        // New / logged-out user: go straight to onboarding → login
        targetPage = const OnboardingPage();
      }

      // Language selection intercept on very first launch
      final needsLang = prefs.getInt('language_selection_version') == null;
      if (needsLang) {
        targetPage = LanguageSelectionPage(next: targetPage);
      }
    } catch (e) {
      debugPrint('Splash nav error: $e');
      targetPage = const OnboardingPage();
    }

    if (!mounted) return;
    AppRoutes.pushReplacement(context, targetPage);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            /// luxury cloth effect
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: CachedNetworkImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1521572267360-ee0c2909d518',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) =>
                      const SizedBox.expand(),
                ),
              ),
            ),

            /// subtle overlay lines
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),

            /// center content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.2),
                          image: const DecorationImage(
                            image: AssetImage(
                              'assets/app_icon/fashiome_app_icon.jpg',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'FashioMe',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'YOUR DIGITAL STYLE CONCIERGE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 220),

                      SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation(Colors.white70),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'INITIALIZING AI INSIGHT ENGINE',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
