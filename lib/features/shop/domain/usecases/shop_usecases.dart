import 'package:fashio_me/features/shop/domain/entities/shop_cart_snapshot.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_item.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_order.dart';
import 'package:fashio_me/features/shop/domain/repositories/shop_repository.dart';

/// Application-facing operations for the shop feature.
/// Presentation receives this facade instead of a repository contract.
class ShopUsecases {
  const ShopUsecases(this._repository);
  final IShopRepository _repository;

  Future<List<ShopItem>> fetchShopItems({int limit = 24}) =>
      _repository.fetchShopItems(limit: limit);
  Future<ShopItem> fetchShopItemById(String id) =>
      _repository.fetchShopItemById(id);
  Future<ShopCartSnapshot> fetchCartItems() => _repository.fetchCartItems();
  Future<void> saveCartItems(Map<String, int> items) =>
      _repository.saveCartItems(items);
  Future<String> placeOrder({
    required String shippingAddress,
    required String customerName,
    required String customerEmail,
    required String phone,
    required String city,
    required String postalCode,
    required String paymentMethod,
  }) => _repository.placeOrder(
    shippingAddress: shippingAddress,
    customerName: customerName,
    customerEmail: customerEmail,
    phone: phone,
    city: city,
    postalCode: postalCode,
    paymentMethod: paymentMethod,
  );
  Future<String> getEsewaPaymentUrl({
    required double amount,
    required String orderId,
    required String productCode,
  }) => _repository.getEsewaPaymentUrl(
    amount: amount,
    orderId: orderId,
    productCode: productCode,
  );
  Future<bool> verifyEsewaPayment({
    required double amount,
    required String orderId,
    required String productCode,
  }) => _repository.verifyEsewaPayment(
    amount: amount,
    orderId: orderId,
    productCode: productCode,
  );
  Future<String> getKhaltiPaymentUrl({
    required double amount,
    required String orderId,
  }) => _repository.getKhaltiPaymentUrl(amount: amount, orderId: orderId);
  Future<bool> verifyKhaltiPayment({required String orderId}) =>
      _repository.verifyKhaltiPayment(orderId: orderId);
  Future<Map<String, String>> createStripePaymentIntent({
    required double amount,
    required String orderId,
  }) => _repository.createStripePaymentIntent(amount: amount, orderId: orderId);
  Future<bool> verifyStripePayment({required String orderId}) =>
      _repository.verifyStripePayment(orderId: orderId);
  Future<List<ShopOrder>> fetchMyOrders() => _repository.fetchMyOrders();
  Future<ShopOrder> fetchOrderById(String id) => _repository.fetchOrderById(id);
  Future<ShopOrder> cancelOrder(String id) => _repository.cancelOrder(id);
  Future<Set<String>> fetchWishlistIds() => _repository.fetchWishlistIds();
  Future<bool> toggleWishlist(String id) => _repository.toggleWishlist(id);
}
