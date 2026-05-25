import 'package:flutter/material.dart';

/// Brand colors for FashioMe dashboard.
abstract final class AppColors {
  static const background = Color(0xFFFCF8F5);
  static const dashboardBackground = Color(0xFFFCF8F5);
  static const navBarBackground = Color(0xFFF5F0EB);
  static const primary = Color(0xFF7A0000);
  static const primaryDark = Color(0xFF40120D);
  static const accent = Color(0xFF9B870C);
  static const navUnselected = Color(0xFF8A8A8A);
  static const textPrimary = Color(0xFF2A2323);
  static const textSecondary = Color(0xFF2A2323);
}

/// Theme — font setup matches [flutter-classwork4] (`Montserrat Bold` family).
ThemeData buildAppTheme() {
  return ThemeData(
    primarySwatch: Colors.amber,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Montserrat Bold',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.primaryDark,
      titleTextStyle: TextStyle(
        color: AppColors.primaryDark,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFF444444),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF666666),
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navBarBackground,
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: AppColors.navUnselected,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 10,
        letterSpacing: 0.5,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 10,
        letterSpacing: 0.5,
      ),
    ),
  );
}
