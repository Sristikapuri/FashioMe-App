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

      // ================= APP TITLE =================
      title: 'FashioMe',

      // ================= INITIAL ROUTE =================
      initialRoute: '/splash',

      // ================= ROUTES =================
      routes: {
        '/splash': (context) => const SplashView(),
        '/onboarding': (context) => const OnboardingView(),
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignupView(),
        '/dashboard': (context) => const DashboardView(),
      },

      // ================= THEME =================
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',

        scaffoldBackgroundColor: const Color(0xFFF8F6F5),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7A0000),
        ),

        // ================= APP BAR =================
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F6F5),
          elevation: 0,
          centerTitle: true,
          foregroundColor: Color(0xFF7A0000),
          titleTextStyle: TextStyle(
            color: Color(0xFF7A0000),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),

        // ================= BUTTONS =================
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7A0000),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // ================= INPUT FIELDS =================
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4EFEF),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),

          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.red.shade100),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF7A0000),
              width: 1.5,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
        ),

        // ================= TEXT THEME =================
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1F1F),
            fontFamily: 'Poppins',
          ),
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1F1F),
            fontFamily: 'Poppins',
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF444444),
            fontFamily: 'Poppins',
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            fontFamily: 'Poppins',
          ),
        ),

        // ================= BOTTOM NAVIGATION =================
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF7A0000),
          unselectedItemColor: Colors.grey,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}