import 'package:flutter/material.dart';

import 'view/splash_view.dart';
import 'view/onboarding_view.dart';
import 'view/login_view.dart';
import 'view/signup_view.dart';
import 'view/dashboard_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FashioMe',

      /// initial screen
      home: const SplashView(),

      /// routes
      routes: {
        '/splash': (context) => const SplashView(),
        '/onboarding': (context) => const OnboardingView(),
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignupView(),
        '/dashboard': (context) => const DashboardView(),
      },

      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF8F6F5),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A0000),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Color(0xFF7A0000),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7A0000),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4EFEF),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.red.shade100,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF7A0000),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}