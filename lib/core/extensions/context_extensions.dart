import 'package:flutter/material.dart';

import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/core/localization/app_strings.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Localized strings for the app's current locale (set via [localeProvider]
  /// and reflected into MaterialApp's `locale`).
  AppStrings get strings => AppStrings.of(Localizations.localeOf(this));

  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  double get viewInsetsBottom => MediaQuery.of(this).viewInsets.bottom;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  void pop<T extends Object?>([T? result]) => Navigator.pop(this, result);
}
