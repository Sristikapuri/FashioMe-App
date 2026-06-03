import 'package:flutter/material.dart';

import 'package:fashio_me/app/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme => _buildTheme();
}

ThemeData _buildTheme() {
  return ThemeData(
    primarySwatch: Colors.amber,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppFonts.regular,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.primaryDark,
      titleTextStyle: TextStyle(
        color: AppColors.primaryDark,
        fontSize: 22,
        fontWeight: FontWeight.w500,
        fontFamily: AppFonts.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontFamily: AppFonts.bold,
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
        fontFamily: AppFonts.bold,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        fontFamily: AppFonts.bold,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        fontFamily: AppFonts.bold,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFF444444),
        fontFamily: AppFonts.regular,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF666666),
        fontFamily: AppFonts.regular,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
        fontFamily: AppFonts.regular,
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
        fontFamily: AppFonts.regular,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 10,
        letterSpacing: 0.5,
        fontFamily: AppFonts.regular,
      ),
    ),
  );
}

/// Backwards-compatible helper used during migration.
ThemeData buildAppTheme() => AppTheme.lightTheme;
