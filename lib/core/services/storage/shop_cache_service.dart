import 'dart:convert';

import 'package:fashio_me/features/shop/data/models/shop_item_model.dart';
import 'package:fashio_me/features/shop/data/models/shop_order_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final shopCacheServiceProvider = Provider<ShopCacheService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return ShopCacheService(prefs: prefs);
});

/// Persists shop data (products, orders, cart, wishlist) to SharedPreferences
/// so that the app works fully offline after the first successful online fetch.
class ShopCacheService {
  ShopCacheService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  // ─── Keys ───────────────────────────────────────────────────────────────────
  static const _kProducts = 'shop_cache_products';
  static const _kOrders = 'shop_cache_orders';
  static const _kCart = 'shop_cache_cart';
  static const _kWishlist = 'shop_cache_wishlist';

  // ─── Products ────────────────────────────────────────────────────────────────

  Future<void> saveProducts(List<ShopItemModel> products) async {
    final encoded = jsonEncode(products.map((p) => p.toJson()).toList());
    await _prefs.setString(_kProducts, encoded);
  }

  List<ShopItemModel> loadProducts() {
    final raw = _prefs.getString(_kProducts);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ShopItemModel.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  bool get hasProducts => (_prefs.getString(_kProducts) ?? '').isNotEmpty;

  // ─── Orders ─────────────────────────────────────────────────────────────────

  Future<void> saveOrders(List<ShopOrderModel> orders) async {
    final encoded = jsonEncode(orders.map((o) => o.toJson()).toList());
    await _prefs.setString(_kOrders, encoded);
  }

  List<ShopOrderModel> loadOrders() {
    final raw = _prefs.getString(_kOrders);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ShopOrderModel.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  bool get hasOrders => (_prefs.getString(_kOrders) ?? '').isNotEmpty;

  // ─── Cart ────────────────────────────────────────────────────────────────────
  // Cart is stored as Map<productId, quantity>

  Future<void> saveCart(Map<String, int> cart) async {
    final encoded = jsonEncode(cart);
    await _prefs.setString(_kCart, encoded);
  }

  Map<String, int> loadCart() {
    final raw = _prefs.getString(_kCart);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return const {};
    }
  }

  Future<void> clearCart() => _prefs.remove(_kCart);

  // ─── Wishlist ────────────────────────────────────────────────────────────────
  // Wishlist is stored as a Set<productId>

  Future<void> saveWishlist(Set<String> wishlistIds) async {
    await _prefs.setStringList(_kWishlist, wishlistIds.toList());
  }

  Set<String> loadWishlist() {
    return (_prefs.getStringList(_kWishlist) ?? []).toSet();
  }
}
