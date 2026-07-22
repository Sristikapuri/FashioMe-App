import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/features/shop/data/datasources/shop_remote_datasource.dart';
import 'package:fashio_me/features/shop/data/models/shop_order_model.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_item.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_order.dart';
import 'package:fashio_me/features/shop/domain/repositories/shop_repository.dart';

final shopRepositoryProvider = Provider<IShopRepository>((ref) {
  return ShopRepositoryImpl(
    remoteDataSource: ref.read(shopRemoteDataSourceProvider),
  );
});

class ShopRepositoryImpl implements IShopRepository {
  ShopRepositoryImpl({required ShopRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final ShopRemoteDataSource _remoteDataSource;

  @override
  Future<Map<String, int>> fetchCartItems() {
    return _remoteDataSource.fetchCartItems();
  }

  @override
  Future<List<ShopOrder>> fetchMyOrders() async {
    final orders = await _remoteDataSource.fetchMyOrders();
    return orders
        .map((order) => ShopOrderModel.fromJson(order).toEntity())
        .toList(growable: false);
  }

  @override
  Future<ShopItem> fetchShopItemById(String id) async {
    final item = await _remoteDataSource.fetchShopItemById(id);
    return item.toEntity();
  }

  @override
  Future<List<ShopItem>> fetchShopItems({
    int page = 1,
    int limit = 24,
    String? search,
    String? category,
  }) async {
    final items = await _remoteDataSource.fetchShopItems(
      page: page,
      limit: limit,
      search: search,
      category: category,
    );
    return items.map((item) => item.toEntity()).toList(growable: false);
  }

  @override
  Future<String> getEsewaPaymentUrl({
    required double amount,
    required String orderId,
    required String productCode,
  }) {
    return _remoteDataSource.getEsewaPaymentUrl(
      amount: amount,
      orderId: orderId,
      productCode: productCode,
    );
  }

  @override
  Future<String> placeOrder({
    required String shippingAddress,
    required String customerName,
    required String customerEmail,
    required String phone,
    required String city,
    required String postalCode,
    required String paymentMethod,
  }) {
    return _remoteDataSource.placeOrder(
      shippingAddress: shippingAddress,
      customerName: customerName,
      customerEmail: customerEmail,
      phone: phone,
      city: city,
      postalCode: postalCode,
      paymentMethod: paymentMethod,
    );
  }

  @override
  Future<void> saveCartItems(Map<String, int> items) {
    return _remoteDataSource.saveCartItems(items);
  }

  @override
  Future<bool> verifyEsewaPayment({
    required double amount,
    required String orderId,
    required String productCode,
  }) {
    return _remoteDataSource.verifyEsewaPayment(
      amount: amount,
      orderId: orderId,
      productCode: productCode,
    );
  }
}
