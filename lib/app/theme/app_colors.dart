import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFFFF7F7);
  static const dashboardBackground = Color(0xFFFFF7F7);
  static const navBarBackground = Color(0xFFF2D8D8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFFFECEC);
  static const surfaceMuted = Color(0xFFF7F2F2);

  static const primary = Color(0xFF820000);
  static const primaryLight = Color(0xFFB83333);
  static const primaryDark = Color(0xFF4A0000);
  static const profileAccent = Color(0xFF820000);
  static const premiumInk = Color(0xFF2A0808);

  static const accent = Color(0xFFA41515);
  static const accentLight = Color(0xFFD86B6B);
  static const accentDark = Color(0xFF5F0000);

  static const navUnselected = Color(0xFF735656);
  static const textPrimary = Color(0xFF260909);
  static const textSecondary = Color(0xFF735656);
  static const textLight = Color(0xFFA98585);
  static const cardBackground = surface;
  static const divider = Color(0xFFE7B8B8);
  static const disabled = Color(0xFFD6A7A7);

  // Semantic colors
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFA41515);
  static const successSoft = Color(0xFFE9F9F3);
  static const errorSoft = Color(0xFFFDECEC);
  static const heroOverlayLight = Color(0x262A0808);
  static const heroOverlayDark = Color(0x732A0808);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFD86B6B), Color(0xFF820000), Color(0xFF4A0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF5F0000), Color(0xFFA41515)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const buttonShadow = [
    BoxShadow(color: Color(0x2E820000), blurRadius: 14, offset: Offset(0, 6)),
  ];

  static const cardShadow = [
    BoxShadow(color: Color(0x172A0808), blurRadius: 18, offset: Offset(0, 8)),
  ];

  static const softShadow = [
    BoxShadow(color: Color(0x18820000), blurRadius: 14, offset: Offset(0, 6)),
  ];
}

/// Montserrat font family names (see pubspec.yaml).
abstract final class AppFonts {
  static const regular = 'Montserrat Regular';
  static const bold = 'Montserrat Bold';
  static const italic = 'Montserrat Italic';
  static const extraBold = 'Montserrat Extra Bold';
}
