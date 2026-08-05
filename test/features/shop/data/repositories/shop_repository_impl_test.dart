import 'package:fashio_me/core/services/storage/shop_cache_service.dart';
import 'package:fashio_me/features/shop/data/datasources/shop_remote_datasource.dart';
import 'package:fashio_me/features/shop/data/models/shop_item_model.dart';
import 'package:fashio_me/features/shop/data/models/shop_order_model.dart';
import 'package:fashio_me/features/shop/data/repositories/shop_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockShopRemoteDataSource extends Mock implements ShopRemoteDataSource {}

class MockShopCacheService extends Mock implements ShopCacheService {}

ShopItemModel _item({String id = '1', double? discountedPrice}) {
  return ShopItemModel(
    id: id,
    name: 'Tailored Coat',
    category: 'tops',
    size: 'M',
    color: 'Camel',
    price: 200.0,
    discountedPrice: discountedPrice,
    stock: 8,
    imageUrl: 'https://example.com/coat.jpg',
    description: 'A warm tailored coat',
    status: 'active',
  );
}

Map<String, dynamic> _orderJson({
  String id = 'order-1',
  String status = 'pending',
}) {
  return {
    '_id': id,
    'status': status,
    'items': <Map<String, dynamic>>[],
    'subtotal': 100.0,
    'total': 105.0,
  };
}

void main() {
  late MockShopRemoteDataSource remote;
  late MockShopCacheService cache;
  late ShopRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(<String, int>{});
    registerFallbackValue(<ShopItemModel>[]);
    registerFallbackValue(<ShopOrderModel>[]);
    registerFallbackValue(<String>[]);
    registerFallbackValue(<String>{});
  });

  setUp(() {
    remote = MockShopRemoteDataSource();
    cache = MockShopCacheService();

    when(() => cache.loadProducts()).thenReturn([]);
    when(() => cache.saveProducts(any())).thenAnswer((_) async {});
    when(() => cache.loadCart()).thenReturn({});
    when(() => cache.saveCart(any())).thenAnswer((_) async {});
    when(() => cache.loadWishlist()).thenReturn({});
    when(() => cache.saveWishlist(any())).thenAnswer((_) async {});
    when(() => cache.loadOrders()).thenReturn([]);
    when(() => cache.saveOrders(any())).thenAnswer((_) async {});

    repository = ShopRepositoryImpl(remoteDataSource: remote, cache: cache);
  });

  test('fetchShopItems maps every remote model to a domain entity', () async {
    when(
      () => remote.fetchShopItems(
        page: 1,
        limit: 24,
        search: null,
        category: null,
      ),
    ).thenAnswer((_) async => [_item(id: '1'), _item(id: '2')]);

    final result = await repository.fetchShopItems();

    expect(result.map((e) => e.id), ['1', '2']);
  });

  test('fetchShopItemById maps the remote model to a domain entity', () async {
    when(() => remote.fetchShopItemById('1')).thenAnswer((_) async => _item());

    final result = await repository.fetchShopItemById('1');

    expect(result.id, '1');
    expect(result.name, 'Tailored Coat');
  });

  test('fetchCartItems maps the bag and item list from the snapshot', () async {
    when(() => remote.fetchCartItems()).thenAnswer(
      (_) async => ShopCartSnapshotModel(bag: const {'1': 2}, items: [_item()]),
    );

    final result = await repository.fetchCartItems();

    expect(result.bag, {'1': 2});
    expect(result.items.single.id, '1');
  });

  test('saveCartItems forwards the map unchanged', () async {
    when(() => remote.saveCartItems(any())).thenAnswer((_) async {});

    await repository.saveCartItems({'1': 3});

    verify(() => remote.saveCartItems({'1': 3})).called(1);
  });

  test(
    'placeOrder forwards checkout details and returns the new order id',
    () async {
      when(
        () => remote.placeOrder(
          shippingAddress: 'Baneshwor',
          customerName: 'Aria',
          customerEmail: 'aria@test.com',
          phone: '9800000000',
          city: 'Kathmandu',
          postalCode: '44600',
          paymentMethod: 'cod',
        ),
      ).thenAnswer((_) async => 'order-1');

      final result = await repository.placeOrder(
        shippingAddress: 'Baneshwor',
        customerName: 'Aria',
        customerEmail: 'aria@test.com',
        phone: '9800000000',
        city: 'Kathmandu',
        postalCode: '44600',
        paymentMethod: 'cod',
      );

      expect(result, 'order-1');
    },
  );

  test('getEsewaPaymentUrl forwards amount, orderId and productCode', () async {
    when(
      () => remote.getEsewaPaymentUrl(
        amount: 105.0,
        orderId: 'order-1',
        productCode: 'EPAYTEST',
      ),
    ).thenAnswer((_) async => 'https://esewa.test/pay');

    final result = await repository.getEsewaPaymentUrl(
      amount: 105.0,
      orderId: 'order-1',
      productCode: 'EPAYTEST',
    );

    expect(result, 'https://esewa.test/pay');
  });

  test(
    'verifyEsewaPayment forwards params and returns the verification flag',
    () async {
      when(
        () => remote.verifyEsewaPayment(
          amount: 105.0,
          orderId: 'order-1',
          productCode: 'EPAYTEST',
        ),
      ).thenAnswer((_) async => true);

      final result = await repository.verifyEsewaPayment(
        amount: 105.0,
        orderId: 'order-1',
        productCode: 'EPAYTEST',
      );

      expect(result, isTrue);
    },
  );

  test('getKhaltiPaymentUrl forwards amount and orderId', () async {
    when(
      () => remote.getKhaltiPaymentUrl(amount: 105.0, orderId: 'order-1'),
    ).thenAnswer((_) async => 'https://khalti.test/pay');

    final result = await repository.getKhaltiPaymentUrl(
      amount: 105.0,
      orderId: 'order-1',
    );

    expect(result, 'https://khalti.test/pay');
  });

  test(
    'verifyKhaltiPayment forwards the orderId and returns the verification flag',
    () async {
      when(
        () => remote.verifyKhaltiPayment(orderId: 'order-1'),
      ).thenAnswer((_) async => true);

      final result = await repository.verifyKhaltiPayment(orderId: 'order-1');

      expect(result, isTrue);
    },
  );

  test(
    'verifyKhaltiPayment surfaces a not-yet-complete payment as false',
    () async {
      when(
        () => remote.verifyKhaltiPayment(orderId: 'order-2'),
      ).thenAnswer((_) async => false);

      final result = await repository.verifyKhaltiPayment(orderId: 'order-2');

      expect(result, isFalse);
    },
  );

  test('createStripePaymentIntent forwards amount and orderId', () async {
    when(
      () => remote.createStripePaymentIntent(amount: 105.0, orderId: 'order-1'),
    ).thenAnswer(
      (_) async => {
        'clientSecret': 'pi_123_secret_456',
        'paymentIntentId': 'pi_123',
      },
    );

    final result = await repository.createStripePaymentIntent(
      amount: 105.0,
      orderId: 'order-1',
    );

    expect(result, {
      'clientSecret': 'pi_123_secret_456',
      'paymentIntentId': 'pi_123',
    });
  });

  test(
    'verifyStripePayment forwards the orderId and returns the verification flag',
    () async {
      when(
        () => remote.verifyStripePayment(orderId: 'order-1'),
      ).thenAnswer((_) async => true);

      final result = await repository.verifyStripePayment(orderId: 'order-1');

      expect(result, isTrue);
    },
  );

  test('fetchMyOrders maps every remote order into a domain entity', () async {
    when(() => remote.fetchMyOrders()).thenAnswer(
      (_) async => [
        _orderJson(id: 'order-1'),
        _orderJson(id: 'order-2', status: 'paid'),
      ],
    );

    final result = await repository.fetchMyOrders();

    expect(result.map((o) => o.id), ['order-1', 'order-2']);
    expect(result.last.status, 'paid');
  });

  test('fetchOrderById maps the remote order into a domain entity', () async {
    when(
      () => remote.fetchOrderById('order-1'),
    ).thenAnswer((_) async => _orderJson());

    final result = await repository.fetchOrderById('order-1');

    expect(result.id, 'order-1');
    expect(result.total, 105.0);
  });

  test(
    'cancelOrder maps the returned order and reflects the cancelled status',
    () async {
      when(
        () => remote.cancelOrder('order-1'),
      ).thenAnswer((_) async => _orderJson(status: 'cancelled'));

      final result = await repository.cancelOrder('order-1');

      expect(result.status, 'cancelled');
    },
  );

  test('fetchWishlistIds forwards the id set unchanged', () async {
    when(() => remote.fetchWishlistIds()).thenAnswer((_) async => {'1', '2'});

    final result = await repository.fetchWishlistIds();

    expect(result, {'1', '2'});
  });

  test(
    'toggleWishlist forwards the id and returns the new saved flag',
    () async {
      when(() => remote.toggleWishlist('1')).thenAnswer((_) async => true);

      final result = await repository.toggleWishlist('1');

      expect(result, isTrue);
    },
  );
}
