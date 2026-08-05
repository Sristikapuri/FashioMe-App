import 'package:dartz/dartz.dart';
import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/has_completed_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/splash/presentation/pages/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHasCompletedSilhouetteProfileUsecase extends Mock
    implements HasCompletedSilhouetteProfileUsecase {}

void main() {
  late MockHasCompletedSilhouetteProfileUsecase mockUsecase;
  late SharedPreferences prefs;

  setUp(() async {
    // language_selection_version present = language already chosen
    SharedPreferences.setMockInitialValues({'language_selection_version': 1});
    prefs = await SharedPreferences.getInstance();
    mockUsecase = MockHasCompletedSilhouetteProfileUsecase();
    when(
      () => mockUsecase.call(),
    ).thenAnswer((_) async => const Right<Failure, bool>(true));
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        hasCompletedSilhouetteProfileUsecaseProvider.overrideWithValue(
          mockUsecase,
        ),
      ],
      child: MaterialApp(theme: ThemeData(useMaterial3: false), home: child),
    );
  }

  Future<void> prepareSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2200));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  group('SplashPage Widget Tests', () {
    testWidgets('shows the splash branding and loading indicator', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const SplashPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('FashioMe'), findsOneWidget);
      expect(find.text('YOUR DIGITAL STYLE CONCIERGE'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Settle remaining timers
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('renders the splash progress message', (tester) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const SplashPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('INITIALIZING AI INSIGHT ENGINE'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
    });
  });
}
