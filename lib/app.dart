import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'view/dashboard_view.dart';
import 'view/splash_view.dart';
import 'view/onboarding_view.dart';
import 'view/login_view.dart';
import 'view/signup_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FashioMe',
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashView(),
        '/onboarding': (context) => const OnboardingView(),
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignupView(),
        '/dashboard': (context) => const DashboardView(),
      },
      theme: buildAppTheme(),
    );
  }
}
