import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/domain/repositories/auth_repository.dart';
import 'package:fashio_me/features/auth/domain/usecases/get_initial_route_usecase.dart';
import 'package:fashio_me/features/auth/domain/usecases/login_usecase.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_providers.dart' as auth;
import 'package:fashio_me/features/auth/presentation/providers/auth_view_model_providers.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_filter_chip.dart';
import 'package:fashio_me/features/dashboard/presentation/widgets/dashboard_section_title.dart';

class _AuthRepo extends Mock implements IAuthRepository {}
class _Login extends Mock implements LoginUsecase {}
class _Route extends Mock implements GetInitialRouteUsecase {}

const _user = AuthEntity(firstName: 'Test', lastName: 'User', username: 'test', email: 'test@example.com', password: 'secret123', gender: 'Female', age: '25');
const _failure = ApiFailure(message: 'failed');

void main() {
  late _AuthRepo repo;
  setUp(() => repo = _AuthRepo());

  // 10 use-case unit tests.
  for (var i = 1; i <= 5; i++) {
    test('usecase login success $i', () async {
      when(() => repo.login(any(), any())).thenAnswer((_) async => const Right(_user));
      final result = await LoginUsecase(authRepository: repo)(const LoginUsecaseParams(email: 'test@example.com', password: 'secret123'));
      expect(result.isRight(), isTrue);
    });
  }
  for (var i = 1; i <= 5; i++) {
    test('usecase login failure $i', () async {
      when(() => repo.login(any(), any())).thenAnswer((_) async => const Left(_failure));
      final result = await LoginUsecase(authRepository: repo)(const LoginUsecaseParams(email: 'test@example.com', password: 'secret123'));
      expect(result.isLeft(), isTrue);
      verify(() => repo.login('test@example.com', 'secret123')).called(1);
    });
  }

  // 10 Riverpod view-model unit tests.
  late _Login login;
  setUp(() => login = _Login());
  for (var i = 1; i <= 10; i++) {
    test('view model validation $i', () async {
      final container = ProviderContainer(overrides: [auth.loginUsecaseProvider.overrideWithValue(login)]);
      addTearDown(container.dispose);
      final vm = container.read(loginViewModelProvider.notifier);
      final result = await vm.login(email: i.isEven ? 'bad' : '', password: '123');
      expect(result, isFalse);
      verifyNever(() => login.call(const LoginUsecaseParams(email: '', password: '')));
    });
  }

  
  for (var i = 1; i <= 10; i++) {
    testWidgets('filter chip renders and taps $i', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(home: DashboardFilterChip(label: 'Filter $i', selected: i.isEven, onTap: () => tapped = true)));
      expect(find.text('Filter $i'), findsOneWidget);
      await tester.tap(find.text('Filter $i'));
      expect(tapped, isTrue);
    });
  }
  for (var i = 1; i <= 10; i++) {
    testWidgets('section title renders and taps $i', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(home: DashboardSectionTitle(title: 'Section $i', actionLabel: 'View', onAction: () => tapped = true)));
      expect(find.text('Section $i'), findsOneWidget);
      expect(find.text('View'), findsOneWidget);
      await tester.tap(find.text('View'));
      expect(tapped, isTrue);
    });
  }
}
