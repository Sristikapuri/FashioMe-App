import 'package:flutter/material.dart';

/// Brand colors and font families for FashioMe.
/// Matches splash screen: Deep maroon with gold accents
abstract final class AppColors {
  static const background = Color(0xFFFCF8F5);
  static const dashboardBackground = Color(0xFFFCF8F5);
  static const navBarBackground = Color(0xFFF5F0EB);
  
  // Primary maroon - matches splash gradient
  static const primary = Color(0xFF7A0000);
  static const primaryLight = Color(0xFFB32D2D);
  static const primaryDark = Color(0xFF5B0000);
  
  // Maroon accent
  static const accent = Color(0xFF7A0000);
  static const accentLight = Color(0xFFB32D2D);
  static const accentDark = Color(0xFF5B0000);
  
  static const navUnselected = Color(0xFF8A8A8A);
  static const textPrimary = Color(0xFF2A2323);
  static const textSecondary = Color(0xFF6B5F5F);
  static const textLight = Color(0xFF9CA3AF);
  static const cardBackground = Color(0xFFFFFFFF);
  static const divider = Color(0xFFE8E0DB);
  static const disabled = Color(0xFFD1D5DB);
  
  // Semantic colors
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  
  // Maroon gradient - matches splash
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF5B0000), Color(0xFF7A0000), Color(0xFF450000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Maroon gradient for accent elements
  static const accentGradient = LinearGradient(
    colors: [Color(0xFF5B0000), Color(0xFF7A0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const buttonShadow = [
    BoxShadow(
      color: Color(0x337A0000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  
  static const cardShadow = [
    BoxShadow(
      color: Color(0x147A0000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
  
  static const softShadow = [
    BoxShadow(
      color: Color(0x0A000000),
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
