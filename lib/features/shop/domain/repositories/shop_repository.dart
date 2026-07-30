import 'package:fashio_me/features/shop/domain/entities/shop_item.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_cart_snapshot.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_order.dart';

abstract interface class IShopRepository {
  Future<List<ShopItem>> fetchShopItems({
    int page = 1,
    int limit = 24,
    String? search,
    String? category,
  });

  Future<ShopItem> fetchShopItemById(String id);

  Future<ShopCartSnapshot> fetchCartItems();

  Future<void> saveCartItems(Map<String, int> items);

  Future<String> placeOrder({
    required String shippingAddress,
    required String customerName,
    required String customerEmail,
    required String phone,
    required String city,
    required String postalCode,
    required String paymentMethod,
  });

  Future<String> getEsewaPaymentUrl({
    required double amount,
    required String orderId,
    required String productCode,
  });

  Future<bool> verifyEsewaPayment({
    required double amount,
    required String orderId,
    required String productCode,
  });

  Future<List<ShopOrder>> fetchMyOrders();

  Future<ShopOrder> fetchOrderById(String id);
  Future<ShopOrder> cancelOrder(String id);
  Future<Set<String>> fetchWishlistIds();
  Future<bool> toggleWishlist(String id);
}
