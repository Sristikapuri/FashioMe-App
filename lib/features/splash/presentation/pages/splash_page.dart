import 'dart:async';

import 'package:fashio_me/app/routes/app_routes.dart';
import 'package:fashio_me/features/auth/presentation/pages/login_page.dart';
import 'package:fashio_me/features/auth/presentation/pages/signup_page.dart';
import 'package:fashio_me/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fashio_me/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:fashio_me/features/splash/presentation/providers/splash_providers.dart';
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

  @override
  void initState() {
    super.initState();

    /// animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    /// fade animation
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    /// scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    Timer(const Duration(seconds: 4), _onSplashFinished);
  }

  Future<void> _onSplashFinished() async {
    if (!mounted) return;
    
    // Resolve the initial route
    await ref.read(splashViewModelProvider.notifier).resolveInitialRoute();
    
    if (!mounted) return;
    
    // Give state a moment to update
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    // Read the resolved route from state
    final state = ref.read(splashViewModelProvider);
    final route = state.targetRoute;
    
    if (route != null && mounted) {
      Widget targetPage;
      switch (route) {
        case 'onboarding':
          targetPage = const OnboardingPage();
          break;
        case 'login':
          targetPage = const LoginPage();
          break;
        case 'signup':
          targetPage = const SignupPage();
          break;
        case 'dashboard':
          targetPage = const DashboardPage();
          break;
        default:
          targetPage = const OnboardingPage();
      }
      AppRoutes.pushReplacement(context, targetPage);
      if (mounted) {
        ref.read(splashViewModelProvider.notifier).clearNavigationTarget();
      }
    }
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5B0000),
              Color(0xFF7A0000),
              Color(0xFF450000),
            ],
          ),
        ),
        child: Stack(
          children: [
            /// luxury cloth effect
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: Image.network(
                  'https://images.unsplash.com/photo-1521572267360-ee0c2909d518',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            /// subtle overlay lines
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),

            /// center content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// logo circle
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFFD27D),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFFFD27D),
                          size: 36,
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// app name
                      const Text(
                        'FashioMe',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD27D),
                          letterSpacing: -1,
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// subtitle
                      const Text(
                        'YOUR DIGITAL STYLE CONCIERGE',
                        style: TextStyle(
                          color: Color(0xFFFFD27D),
                          fontSize: 12,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 220),

                      /// loading line
                      SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFFFFD27D),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// loading text
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

/// background grid painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    /// vertical line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    /// horizontal line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}