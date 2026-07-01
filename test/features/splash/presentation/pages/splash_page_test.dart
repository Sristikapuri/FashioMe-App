import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/has_completed_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/splash/presentation/pages/splash_page.dart';
import 'package:fashio_me/features/splash/presentation/state/splash_state.dart';
import 'package:fashio_me/features/splash/presentation/view_model/splash_view_model.dart';
import 'package:fashio_me/features/splash/presentation/providers/splash_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHasCompletedSilhouetteProfileUsecase extends Mock
    implements HasCompletedSilhouetteProfileUsecase {}

class FakeSplashViewModel extends SplashViewModel {
  @override
  SplashState build() => const SplashState.initial();

  Future<void> resolveInitialRoute() async {}

  void clearNavigationTarget() {}
}

void main() {
  late MockHasCompletedSilhouetteProfileUsecase mockUsecase;

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        splashViewModelProvider.overrideWith(FakeSplashViewModel.new),
        hasCompletedSilhouetteProfileUsecaseProvider.overrideWithValue(
          mockUsecase,
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: child,
      ),
    );
  }

  Future<void> prepareSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2200));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  setUp(() {
    mockUsecase = MockHasCompletedSilhouetteProfileUsecase();
    when(() => mockUsecase.call()).thenAnswer(
      (_) async => const Right<Failure, bool>(true),
    );
  });

  group('SplashPage Widget Tests', () {
    testWidgets('shows the splash branding and loading indicator', (tester) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const SplashPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 4100));
      await tester.pump();

      expect(find.text('FashioMe'), findsOneWidget);
      expect(find.text('YOUR DIGITAL STYLE CONCIERGE'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders the splash progress message', (tester) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const SplashPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 4100));
      await tester.pump();

      expect(find.text('INITIALIZING AI INSIGHT ENGINE'), findsOneWidget);
    });

  });
}
