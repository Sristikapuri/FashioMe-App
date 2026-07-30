import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/theme/app_theme.dart';
import 'package:fashio_me/core/localization/locale_notifier.dart';
import 'package:fashio_me/core/navigation/app_navigator.dart';
import 'package:fashio_me/features/splash/presentation/pages/splash_page.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'FashioMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashPage(),
    );
  }
}
