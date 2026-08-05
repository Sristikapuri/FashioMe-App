import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fashio_me/app/theme/app_colors.dart';
import 'package:fashio_me/app/app.dart';
import 'package:fashio_me/core/config/stripe_config.dart';
import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:fashio_me/features/auth/data/services/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Configure Stripe safely so initialization errors on native device never
  // block runApp() or freeze the splash screen.
  try {
    Stripe.publishableKey = StripeConfig.publishableKey;
    await Stripe.instance.applySettings();
  } catch (e) {
    debugPrint('Stripe initialization notice: $e');
  }

  // Initialize local Hive storage safely
  try {
    await HiveService().init();
  } catch (e) {
    debugPrint('Hive initialization notice: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}
