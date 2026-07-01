import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/usecases/register_usecase.dart';
import 'package:fashio_me/features/auth/presentation/pages/signup_page.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_providers.dart' as auth_providers;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRegisterUsecase extends Mock implements RegisterUsecase {}
class FakeRegisterUsecaseParams extends Fake implements RegisterUsecaseParams {}

void main() {
  late MockRegisterUsecase mockRegisterUsecase;

  setUpAll(() {
    registerFallbackValue(FakeRegisterUsecaseParams());
  });

  setUp(() {
    mockRegisterUsecase = MockRegisterUsecase();
    when(() => mockRegisterUsecase.call(any())).thenAnswer(
      (_) async => const Right<Failure, AuthEntity>(
        AuthEntity(
          firstName: 'Test',
          lastName: 'User',
          username: 'testuser',
          email: 'test@example.com',
        ),
      ),
    );
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        auth_providers.registerUsecaseProvider.overrideWithValue(mockRegisterUsecase),
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

  group('SignupPage Widget Tests', () {
    testWidgets('Signup page shows create account text', (tester) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const SignupPage()));

      expect(find.widgetWithText(ElevatedButton, 'Create Account'), findsOneWidget);
      expect(find.text('Join the luxury fashion experience.'), findsOneWidget);
    });

    testWidgets('Signup page shows the gender selector', (tester) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const SignupPage()));

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

  });
}
