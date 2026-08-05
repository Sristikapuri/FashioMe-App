import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:fashio_me/core/services/sensors/sensor_settings.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_session_providers.dart';
import 'package:fashio_me/features/auth/presentation/state/auth_session_state.dart';
import 'package:fashio_me/features/auth/presentation/view_model/auth_session_view_model.dart';
import 'package:fashio_me/features/shop/data/datasources/shop_remote_datasource.dart';
import 'package:fashio_me/features/shop/data/models/shop_item_model.dart';
import 'package:fashio_me/features/shop/presentation/pages/shop_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockShopRemoteDataSource extends Mock implements ShopRemoteDataSource {}

/// Bypasses the real session usecases entirely so ShopPage's `initState`
/// read of `authSessionViewModelProvider` never touches network/storage.
class _FakeAuthSessionViewModel extends AuthSessionViewModel {
  @override
  AuthSessionState build() => const AuthSessionState.initial();
}

ShopItemModel _item({
  String id = '1',
  String name = 'Tailored Coat',
  double? discountedPrice,
  int stock = 8,
}) {
  return ShopItemModel(
    id: id,
    name: name,
    category: 'tops',
    size: 'M',
    color: 'Camel',
    price: 200.0,
    discountedPrice: discountedPrice,
    stock: stock,
    imageUrl: 'https://example.com/coat.jpg',
    description: 'A warm tailored coat',
    status: 'active',
  );
}

void main() {
  late MockShopRemoteDataSource mockRemote;
  late SharedPreferences prefs;

  Future<void> prepareSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        shopRemoteDataSourceProvider.overrideWithValue(mockRemote),
        sharedPreferencesProvider.overrideWithValue(prefs),
        authSessionViewModelProvider.overrideWith(
          _FakeAuthSessionViewModel.new,
        ),
      ],
      child: MaterialApp(theme: ThemeData(useMaterial3: false), home: child),
    );
  }

  setUpAll(() {
    registerFallbackValue(<String, int>{});
  });

  setUp(() async {
    mockRemote = MockShopRemoteDataSource();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    when(
      () => mockRemote.fetchShopItems(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        search: any(named: 'search'),
        category: any(named: 'category'),
      ),
    ).thenAnswer((_) async => [_item()]);
    when(
      () => mockRemote.fetchCartItems(),
    ).thenAnswer((_) async => const ShopCartSnapshotModel());
    when(() => mockRemote.saveCartItems(any())).thenAnswer((_) async {});
    when(
      () => mockRemote.fetchWishlistIds(),
    ).thenAnswer((_) async => <String>{});
    when(() => mockRemote.toggleWishlist(any())).thenAnswer((_) async => true);
  });

  group('ShopPage Widget Tests', () {
    testWidgets('shows the shop title and search field', (tester) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const ShopPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Search products'), findsOneWidget);
    });

    testWidgets('renders a fetched item name and its Add to bag button', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const ShopPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tailored Coat'), findsWidgets);
      expect(find.text('Add to bag'), findsWidgets);
    });

    testWidgets('tapping Add to bag saves the updated cart', (tester) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const ShopPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Add to bag').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockRemote.saveCartItems({'1': 1})).called(1);
    });

    testWidgets('tapping the wishlist icon toggles it on the backend', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const ShopPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockRemote.toggleWishlist('1')).called(1);
    });

    testWidgets('selecting a category chip filters out non-matching items', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const ShopPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tailored Coat'), findsWidgets);

      await tester.tap(find.widgetWithText(ChoiceChip, 'dresses'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tailored Coat'), findsNothing);
    });

    testWidgets('the Low Stock segment hides items above the threshold', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const ShopPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Tailored Coat'), findsWidgets);

      await tester.tap(find.text('Low Stock'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // stock: 8 is above the low-stock threshold, so it drops out of view.
      expect(find.text('Tailored Coat'), findsNothing);
    });

    testWidgets(
      'a discounted item renders in the Featured Deals row without overflowing',
      (tester) async {
        await prepareSurface(tester);
        when(
          () => mockRemote.fetchShopItems(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
            search: any(named: 'search'),
            category: any(named: 'category'),
          ),
        ).thenAnswer((_) async => [_item(discountedPrice: 150.0)]);

        await tester.pumpWidget(wrap(const ShopPage()));
        await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Featured Deals'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'enabling sensor gestures does not crash the page (regression)',
      (tester) async {
        await prepareSurface(tester);
        await prefs.setBool(sensorGesturesEnabledKey, true);

        await tester.pumpWidget(wrap(const ShopPage()));
        await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

        // Historically `ref.listen` was (incorrectly) called from initState
        // instead of build, which threw a Riverpod assertion on every open of
        // this page regardless of whether gestures were actually enabled.
        expect(tester.takeException(), isNull);
        expect(find.text('Shop'), findsOneWidget);
      },
    );

    testWidgets(
      'toggling sensor gestures on after the page is open does not crash',
      (tester) async {
        await prepareSurface(tester);

        await tester.pumpWidget(wrap(const ShopPage()));
        await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

        final element = tester.element(find.text('Shop'));
        await ProviderScope.containerOf(
          element,
        ).read(sensorGesturesEnabledProvider.notifier).setEnabled(true);
        await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('selecting the Female gender filter marks that chip selected', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const ShopPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.widgetWithText(ChoiceChip, 'Female'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final femaleChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Female'),
      );
      final allChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'All').first,
      );
      expect(femaleChip.selected, isTrue);
      expect(allChip.selected, isFalse);
    });

    testWidgets('leaving the page after enabling gestures disposes cleanly', (
      tester,
    ) async {
      await prepareSurface(tester);
      await prefs.setBool(sensorGesturesEnabledKey, true);

      await tester.pumpWidget(wrap(const ShopPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
