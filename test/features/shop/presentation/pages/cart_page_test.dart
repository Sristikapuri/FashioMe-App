import 'package:fashio_me/core/services/storage/shop_cache_service.dart';
import 'package:fashio_me/features/shop/data/datasources/shop_remote_datasource.dart';
import 'package:fashio_me/features/shop/data/models/shop_item_model.dart';
import 'package:fashio_me/features/shop/data/models/shop_order_model.dart';
import 'package:fashio_me/features/shop/presentation/pages/cart_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockShopRemoteDataSource extends Mock implements ShopRemoteDataSource {}

class MockShopCacheService extends Mock implements ShopCacheService {}

ShopItemModel _item() {
  return const ShopItemModel(
    id: '1',
    name: 'Tailored Coat',
    category: 'tops',
    size: 'M',
    color: 'Camel',
    price: 200.0,
    discountedPrice: 150.0,
    stock: 8,
    imageUrl: 'https://example.com/coat.jpg',
    description: 'A warm tailored coat',
    status: 'active',
  );
}

void main() {
  late MockShopRemoteDataSource mockRemote;
  late MockShopCacheService mockCache;

  Future<void> prepareSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        shopRemoteDataSourceProvider.overrideWithValue(mockRemote),
        shopCacheServiceProvider.overrideWithValue(mockCache),
      ],
      child: MaterialApp(theme: ThemeData(useMaterial3: false), home: child),
    );
  }

  setUpAll(() {
    registerFallbackValue(<String, int>{});
    registerFallbackValue(<ShopItemModel>[]);
    registerFallbackValue(<ShopOrderModel>[]);
  });

  setUp(() {
    mockRemote = MockShopRemoteDataSource();
    mockCache = MockShopCacheService();

    when(() => mockCache.loadCart()).thenReturn({});
    when(() => mockCache.saveCart(any())).thenAnswer((_) async {});
    when(() => mockCache.loadProducts()).thenReturn([]);
    when(() => mockCache.saveProducts(any())).thenAnswer((_) async {});
    when(() => mockCache.loadWishlist()).thenReturn({});
    when(() => mockCache.saveWishlist(any())).thenAnswer((_) async {});
    when(() => mockCache.loadOrders()).thenReturn([]);
    when(() => mockCache.saveOrders(any())).thenAnswer((_) async {});

    when(
      () => mockRemote.fetchCartItems(),
    ).thenAnswer((_) async => const ShopCartSnapshotModel());
    when(
      () => mockRemote.fetchShopItems(limit: 100),
    ).thenAnswer((_) async => [_item()]);
    when(() => mockRemote.saveCartItems(any())).thenAnswer((_) async {});
    when(
      () => mockRemote.placeOrder(
        shippingAddress: any(named: 'shippingAddress'),
        customerName: any(named: 'customerName'),
        customerEmail: any(named: 'customerEmail'),
        phone: any(named: 'phone'),
        city: any(named: 'city'),
        postalCode: any(named: 'postalCode'),
        paymentMethod: any(named: 'paymentMethod'),
      ),
    ).thenAnswer((_) async => 'order_123');
  });

  group('CartPage Widget Tests', () {
    testWidgets('shows an empty cart message when there are no items', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const CartPage()));
      await tester.pumpAndSettle();

      expect(find.text('Your cart is empty.'), findsOneWidget);
      expect(find.text('My Cart'), findsOneWidget);
    });

    testWidgets('removes an item when the remove button is tapped', (
      tester,
    ) async {
      await prepareSurface(tester);
      when(() => mockRemote.fetchCartItems()).thenAnswer(
        (_) async =>
            ShopCartSnapshotModel(bag: const {'1': 1}, items: [_item()]),
      );

      await tester.pumpWidget(wrap(const CartPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockRemote.saveCartItems(any())).called(1);
      expect(find.text('Your cart is empty.'), findsOneWidget);
    });

    group('payment method selection', () {
      Future<void> pumpCartWithItems(WidgetTester tester) async {
        await prepareSurface(tester);
        when(() => mockRemote.fetchCartItems()).thenAnswer(
          (_) async =>
              ShopCartSnapshotModel(bag: const {'1': 1}, items: [_item()]),
        );

        await tester.pumpWidget(wrap(const CartPage()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      testWidgets('shows both payment methods once the cart has items', (
        tester,
      ) async {
        await pumpCartWithItems(tester);

        expect(find.widgetWithText(ChoiceChip, 'COD'), findsOneWidget);
        expect(find.text('Stripe'), findsOneWidget);
      });

      testWidgets('does not offer eSewa as a payment method', (tester) async {
        await pumpCartWithItems(tester);

        expect(find.widgetWithText(ChoiceChip, 'eSewa'), findsNothing);
        expect(find.text('Pay with eSewa'), findsNothing);
      });

      testWidgets('defaults to COD with the matching button label', (
        tester,
      ) async {
        await pumpCartWithItems(tester);

        final codChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'COD'),
        );
        expect(codChip.selected, isTrue);
        expect(
          find.widgetWithText(ElevatedButton, 'Place Order (COD)'),
          findsOneWidget,
        );
      });

      testWidgets('selecting Stripe switches the checkout button label', (
        tester,
      ) async {
        await pumpCartWithItems(tester);

        await tester.tap(find.text('Stripe'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.widgetWithText(ElevatedButton, 'Pay with Stripe'),
          findsOneWidget,
        );
      });

      testWidgets('selecting Stripe deselects the default COD choice', (
        tester,
      ) async {
        await pumpCartWithItems(tester);

        await tester.tap(find.text('Stripe'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final codChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'COD'),
        );
        expect(codChip.selected, isFalse);
      });

      testWidgets(
        'switching back to COD after Stripe reverts the button label',
        (tester) async {
          await pumpCartWithItems(tester);

          await tester.tap(find.text('Stripe'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.widgetWithText(ChoiceChip, 'COD'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(
            find.widgetWithText(ElevatedButton, 'Place Order (COD)'),
            findsOneWidget,
          );
        },
      );
    });
  });
}
