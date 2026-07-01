import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/usecases/login_usecase.dart';
import 'package:fashio_me/features/auth/presentation/pages/login_page.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_providers.dart' as auth_providers;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUsecase extends Mock implements LoginUsecase {}
class FakeLoginUsecaseParams extends Fake implements LoginUsecaseParams {}

void main() {
  late MockLoginUsecase mockLoginUsecase;

  setUpAll(() {
    registerFallbackValue(FakeLoginUsecaseParams());
  });

  setUp(() {
    mockLoginUsecase = MockLoginUsecase();
    when(() => mockLoginUsecase.call(any())).thenAnswer(
      (_) async => const Left<Failure, AuthEntity>(ApiFailure(message: 'invalid')),
    );
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        auth_providers.loginUsecaseProvider.overrideWithValue(mockLoginUsecase),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: child,
      ),
    );
  }

  Future<void> prepareSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  group('LoginPage Widget Tests', () {
    testWidgets('Login page shows welcome text', (tester) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const LoginPage()));

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(
        find.text('Sign in to continue your style journey.'),
        findsOneWidget,
      );
    });

    testWidgets('Login page shows the create account button', (tester) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const LoginPage()));

      expect(find.widgetWithText(OutlinedButton, 'Create New Account'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

  });
}
