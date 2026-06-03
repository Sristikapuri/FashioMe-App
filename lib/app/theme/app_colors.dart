import 'package:flutter/material.dart';

/// Brand colors and font families for FashioMe.
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
  
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const buttonShadow = [
    BoxShadow(
      color: Color(0x33FF6B6B),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

/// Montserrat font family names (see pubspec.yaml).
abstract final class AppFonts {
  static const regular = 'Montserrat Regular';
  static const bold = 'Montserrat Bold';
  static const italic = 'Montserrat Italic';
  static const extraBold = 'Montserrat Extra Bold';
}
