import 'package:fashio_me/core/services/storage/shop_cache_service.dart';
import 'package:fashio_me/features/shop/data/datasources/shop_remote_datasource.dart';
import 'package:fashio_me/features/shop/data/models/shop_order_model.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_cart_snapshot.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_item.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_order.dart';
import 'package:fashio_me/features/shop/domain/repositories/shop_repository.dart';

class ShopRepositoryImpl implements IShopRepository {
  ShopRepositoryImpl({
    required ShopRemoteDataSource remoteDataSource,
    required ShopCacheService cache,
  })  : _remoteDataSource = remoteDataSource,
        _cache = cache;

  final ShopRemoteDataSource _remoteDataSource;
  final ShopCacheService _cache;

  // ─── Products ─────────────────────────────────────────────────────────────

  @override
  Future<List<ShopItem>> fetchShopItems({
    int page = 1,
    int limit = 24,
    String? search,
    String? category,
  }) async {
    try {
      final models = await _remoteDataSource.fetchShopItems(
        page: page,
        limit: limit,
        search: search,
        category: category,
      );
      // Persist to disk: merge with existing cache (avoid duplicates)
      if (models.isNotEmpty) {
        final existing = _cache.loadProducts();
        final existingIds = existing.map((m) => m.id).toSet();
        final merged = [
          ...existing,
          ...models.where((m) => !existingIds.contains(m.id)),
        ];
        await _cache.saveProducts(merged);
      }
      return models.map((m) => m.toEntity()).toList(growable: false);
    } catch (_) {
      // Offline: return from disk cache with filtering
      final cached = _cache.loadProducts();
      if (cached.isNotEmpty) {
        var filtered = cached;
        if (category != null && category.isNotEmpty && category != 'All') {
          filtered = filtered
              .where((m) => m.category.toLowerCase() == category.toLowerCase())
              .toList();
        }
        if (search != null && search.isNotEmpty) {
          filtered = filtered
              .where((m) =>
                  m.name.toLowerCase().contains(search.toLowerCase()))
              .toList();
        }
        return filtered.map((m) => m.toEntity()).toList(growable: false);
      }
      rethrow;
    }
  }

  @override
  Future<ShopItem> fetchShopItemById(String id) async {
    try {
      final item = await _remoteDataSource.fetchShopItemById(id);
      return item.toEntity();
    } catch (_) {
      // Try disk cache first
      final cached = _cache.loadProducts();
      final found = cached.where((m) => m.id == id).firstOrNull;
      if (found != null) return found.toEntity();
      rethrow;
    }
  }

  // ─── Cart ─────────────────────────────────────────────────────────────────

  @override
  Future<ShopCartSnapshot> fetchCartItems() async {
    try {
      final snapshot = await _remoteDataSource.fetchCartItems();
      // Persist cart locally after every successful fetch
      await _cache.saveCart(snapshot.bag);
      return ShopCartSnapshot(
        bag: snapshot.bag,
        items: snapshot.items.map((item) => item.toEntity()).toList(growable: false),
      );
    } catch (_) {
      // Offline: rebuild snapshot from cached cart + cached products
      final bag = _cache.loadCart();
      final products = _cache.loadProducts();
      final items = bag.entries
          .map((entry) {
            final model = products.where((p) => p.id == entry.key).firstOrNull;
            if (model == null) return null;
            return model.toEntity();
          })
          .whereType<ShopItem>()
          .toList(growable: false);
      return ShopCartSnapshot(bag: bag, items: items);
    }
  }

  @override
  Future<void> saveCartItems(Map<String, int> items) async {
    // Always persist cart locally immediately (works offline)
    await _cache.saveCart(items);
    try {
      await _remoteDataSource.saveCartItems(items);
    } catch (_) {
      // Best-effort: local save already done above, will sync on next online session
    }
  }

  // ─── Wishlist ─────────────────────────────────────────────────────────────

  @override
  Future<Set<String>> fetchWishlistIds() async {
    try {
      final ids = await _remoteDataSource.fetchWishlistIds();
      await _cache.saveWishlist(ids);
      return ids;
    } catch (_) {
      return _cache.loadWishlist();
    }
  }

  @override
  Future<bool> toggleWishlist(String id) async {
    try {
      final result = await _remoteDataSource.toggleWishlist(id);
      // Update local cache optimistically
      final current = _cache.loadWishlist();
      if (current.contains(id)) {
        current.remove(id);
      } else {
        current.add(id);
      }
      await _cache.saveWishlist(current);
      return result;
    } catch (_) {
      // Offline: toggle locally only
      final current = _cache.loadWishlist();
      if (current.contains(id)) {
        current.remove(id);
      } else {
        current.add(id);
      }
      await _cache.saveWishlist(current);
      return current.contains(id);
    }
  }

  // ─── Orders ───────────────────────────────────────────────────────────────

  @override
  Future<List<ShopOrder>> fetchMyOrders() async {
    try {
      final rawList = await _remoteDataSource.fetchMyOrders();
      final models =
          rawList.map((raw) => ShopOrderModel.fromJson(raw)).toList();
      await _cache.saveOrders(models);
      return models.map((m) => m.toEntity()).toList(growable: false);
    } catch (_) {
      final cached = _cache.loadOrders();
      return cached.map((m) => m.toEntity()).toList(growable: false);
    }
  }

  @override
  Future<ShopOrder> fetchOrderById(String id) async {
    try {
      final order = await _remoteDataSource.fetchOrderById(id);
      return ShopOrderModel.fromJson(order).toEntity();
    } catch (_) {
      final cached = _cache.loadOrders();
      final found = cached.where((m) => m.id == id).firstOrNull;
      if (found != null) return found.toEntity();
      rethrow;
    }
  }

  @override
  Future<ShopOrder> cancelOrder(String id) async {
    final order = await _remoteDataSource.cancelOrder(id);
    // Refresh orders cache after cancellation
    try {
      final rawList = await _remoteDataSource.fetchMyOrders();
      await _cache.saveOrders(
          rawList.map((raw) => ShopOrderModel.fromJson(raw)).toList());
    } catch (_) {}
    return ShopOrderModel.fromJson(order).toEntity();
  }

  // ─── Payment (online-only) ─────────────────────────────────────────────────

  @override
  Future<String> getEsewaPaymentUrl({
    required double amount,
    required String orderId,
    required String productCode,
  }) =>
      _remoteDataSource.getEsewaPaymentUrl(
        amount: amount,
        orderId: orderId,
        productCode: productCode,
      );

  @override
  Future<String> placeOrder({
    required String shippingAddress,
    required String customerName,
    required String customerEmail,
    required String phone,
    required String city,
    required String postalCode,
    required String paymentMethod,
  }) =>
      _remoteDataSource.placeOrder(
        shippingAddress: shippingAddress,
        customerName: customerName,
        customerEmail: customerEmail,
        phone: phone,
        city: city,
        postalCode: postalCode,
        paymentMethod: paymentMethod,
      );

  @override
  Future<bool> verifyEsewaPayment({
    required double amount,
    required String orderId,
    required String productCode,
  }) =>
      _remoteDataSource.verifyEsewaPayment(
        amount: amount,
        orderId: orderId,
        productCode: productCode,
      );

  @override
  Future<String> getKhaltiPaymentUrl({
    required double amount,
    required String orderId,
  }) =>
      _remoteDataSource.getKhaltiPaymentUrl(amount: amount, orderId: orderId);

  @override
  Future<bool> verifyKhaltiPayment({required String orderId}) =>
      _remoteDataSource.verifyKhaltiPayment(orderId: orderId);

  @override
  Future<Map<String, String>> createStripePaymentIntent({
    required double amount,
    required String orderId,
  }) =>
      _remoteDataSource.createStripePaymentIntent(
          amount: amount, orderId: orderId);

  @override
  Future<bool> verifyStripePayment({required String orderId}) =>
      _remoteDataSource.verifyStripePayment(orderId: orderId);
}
