import 'package:fashio_me/core/services/storage/shop_cache_service.dart';
import 'package:fashio_me/features/shop/data/datasources/shop_remote_datasource.dart';
import 'package:fashio_me/features/shop/data/models/shop_item_model.dart';
import 'package:fashio_me/features/shop/data/models/shop_order_model.dart';
import 'package:fashio_me/features/shop/presentation/pages/order_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockShopRemoteDataSource extends Mock implements ShopRemoteDataSource {}

class MockShopCacheService extends Mock implements ShopCacheService {}

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
      child: MaterialApp(home: child),
    );
  }

  setUpAll(() {
    registerFallbackValue(<ShopItemModel>[]);
    registerFallbackValue(<ShopOrderModel>[]);
  });

  setUp(() {
    mockRemote = MockShopRemoteDataSource();
    mockCache = MockShopCacheService();

    when(() => mockCache.loadOrders()).thenReturn([]);
    when(() => mockCache.saveOrders(any())).thenAnswer((_) async {});
    when(() => mockCache.loadCart()).thenReturn({});
    when(() => mockCache.saveCart(any())).thenAnswer((_) async {});
    when(() => mockCache.loadProducts()).thenReturn([]);
    when(() => mockCache.saveProducts(any())).thenAnswer((_) async {});
    when(() => mockCache.loadWishlist()).thenReturn({});
    when(() => mockCache.saveWishlist(any())).thenAnswer((_) async {});

    when(
      () => mockRemote.fetchMyOrders(),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);
  });

  group('OrderHistoryPage Widget Tests', () {
    testWidgets('shows the empty-state message when there are no orders', (
      tester,
    ) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const OrderHistoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('No orders yet.'), findsOneWidget);
      expect(find.text('Order History'), findsOneWidget);
    });

    testWidgets('renders an order card with item chips', (tester) async {
      await prepareSurface(tester);
      when(() => mockRemote.fetchMyOrders()).thenAnswer(
        (_) async => [
          {
            '_id': 'abc123456',
            'status': 'delivered',
            'items': [
              {'name': 'Tailored Coat', 'quantity': 2},
              {'name': 'Silk Dress', 'quantity': 1},
            ],
            'subtotal': 300,
            'total': 315,
          },
        ],
      );

      await tester.pumpWidget(wrap(const OrderHistoryPage()));
      await tester.pumpAndSettle();

      expect(find.text('Order #abc123'), findsOneWidget);
      expect(find.text('DELIVERED'), findsOneWidget);
      expect(find.text('Tailored Coat x2'), findsOneWidget);
    });
  });
}
