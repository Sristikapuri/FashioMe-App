import 'package:fashio_me/features/shop/data/datasources/shop_remote_datasource.dart';
import 'package:fashio_me/features/shop/data/models/shop_item_model.dart';
import 'package:fashio_me/features/shop/presentation/pages/cart_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockShopRemoteDataSource extends Mock implements ShopRemoteDataSource {}

ShopItemModel _item() {
  return const ShopItemModel(
    id: '1',
    name: 'Tailored Coat',
    category: 'tops',
    size: 'M',
    color: 'Camel',
    price: 200,
    discountedPrice: 150,
    stock: 8,
    imageUrl: 'https://example.com/coat.jpg',
    description: 'A warm tailored coat',
    status: 'active',
  );
}

void main() {
  late MockShopRemoteDataSource mockRemote;

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
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: child,
      ),
    );
  }

  setUp(() {
    mockRemote = MockShopRemoteDataSource();
    when(() => mockRemote.fetchCartItems()).thenAnswer((_) async => <String, int>{});
    when(() => mockRemote.fetchShopItems(limit: 100)).thenAnswer((_) async => [_item()]);
    when(() => mockRemote.saveCartItems(any())).thenAnswer((_) async {});
    when(() => mockRemote.placeOrder(shippingAddress: any(named: 'shippingAddress'))).thenAnswer((_) async {});
  });

  group('CartPage Widget Tests', () {
    testWidgets('shows an empty cart message when there are no items', (tester) async {
      await prepareSurface(tester);

      await tester.pumpWidget(wrap(const CartPage()));
      await tester.pumpAndSettle();

      expect(find.text('Your cart is empty.'), findsOneWidget);
      expect(find.text('My Cart'), findsOneWidget);
    });

    testWidgets('removes an item when the remove button is tapped', (tester) async {
      await prepareSurface(tester);
      when(() => mockRemote.fetchCartItems()).thenAnswer((_) async => {'1': 1});

      await tester.pumpWidget(wrap(const CartPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      verify(() => mockRemote.saveCartItems(any())).called(1);
      expect(find.text('Your cart is empty.'), findsOneWidget);
    });
  });
}
