import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/features/shop/data/models/shop_item_model.dart';

class ShopCartSnapshotModel {
  const ShopCartSnapshotModel({this.bag = const {}, this.items = const []});

  final Map<String, int> bag;
  final List<ShopItemModel> items;
}

final shopRemoteDataSourceProvider = Provider<ShopRemoteDataSource>((ref) {
  return ShopRemoteDataSource(apiClient: ref.read(apiClientProvider));
});

class ShopRemoteDataSource {
  ShopRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<ShopCartSnapshotModel> fetchCartItems() async {
    final response = await _apiClient.get(ApiEndpoints.cart);
    final data = response.data;
    final payload = data is Map<String, dynamic> ? data['responseData'] : null;
    final items = payload is Map<String, dynamic> ? payload['items'] : null;

    if (items is! List) {
      return const ShopCartSnapshotModel();
    }

    final bag = <String, int>{};
    final cartItems = <ShopItemModel>[];
    for (final item in items.whereType<Map>()) {
      final clothe = item['clothe'];
      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      if (clothe is Map && quantity > 0) {
        final id = (clothe['_id'] ?? clothe['id'] ?? '').toString();
        if (id.isNotEmpty) {
          bag[id] = quantity;
          cartItems.add(
            ShopItemModel.fromJson(Map<String, dynamic>.from(clothe)),
          );
        }
      }
    }

    return ShopCartSnapshotModel(bag: bag, items: cartItems);
  }

  Future<void> saveCartItems(Map<String, int> items) async {
    await _apiClient.put(
      ApiEndpoints.cart,
      data: {
        'items': items.entries
            .map((entry) => {'clotheId': entry.key, 'quantity': entry.value})
            .toList(),
      },
    );
  }

  Future<String> placeOrder({
    required String shippingAddress,
    required String customerName,
    required String customerEmail,
    required String phone,
    required String city,
    required String postalCode,
    required String paymentMethod,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.orders,
      data: {
        'shippingAddress': shippingAddress,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'phone': phone,
        'city': city,
        'postalCode': postalCode,
        'paymentMethod': paymentMethod,
      },
    );

    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    final order = payload is Map ? payload['order'] : null;
    final id = order is Map
        ? (order['_id'] ?? order['id'] ?? '').toString()
        : '';
    if (id.isEmpty) {
      throw StateError('Order ID missing from backend response');
    }
    return id;
  }

  Future<String> getEsewaPaymentUrl({
    required double amount,
    required String orderId,
    required String productCode,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.esewaPaymentUrl,
      queryParameters: {
        'amount': amount,
        'orderId': orderId,
        'productCode': productCode,
        // Tells the backend whether the eSewa success/failure redirect
        // should hand back to this app via a custom URL scheme (mobile) or
        // to the web dashboard (web build).
        'platform': kIsWeb ? 'web' : 'mobile',
      },
    );

    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    final paymentUrl = payload is Map
        ? payload['paymentUrl']?.toString()
        : null;

    if (paymentUrl == null || paymentUrl.isEmpty) {
      throw StateError('Failed to generate payment URL from backend');
    }
    return paymentUrl;
  }

  Future<bool> verifyEsewaPayment({
    required double amount,
    required String orderId,
    required String productCode,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.esewaVerify,
      data: {'amount': amount, 'orderId': orderId, 'productCode': productCode},
    );

    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    return payload is Map ? payload['verified'] == true : false;
  }

  String _extractMessage(dynamic data, {required String fallback}) {
    if (data is Map<String, dynamic>) {
      final message = data['responseMessage'] ?? data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return fallback;
  }

  String _readErrorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      final extracted = _extractMessage(error.response?.data, fallback: '');
      if (extracted.isNotEmpty) return extracted;
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    if (error is Exception) {
      final msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        final trimmed = msg.substring('Exception: '.length).trim();
        if (trimmed.isNotEmpty) return trimmed;
      }
      return msg;
    }
    return fallback;
  }

  Future<String> getKhaltiPaymentUrl({
    required double amount,
    required String orderId,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.khaltiPaymentUrl,
        queryParameters: {
          'amount': amount,
          'orderId': orderId,
          // Tells the backend whether the Khalti return_url should hand back
          // to this app via a custom URL scheme (mobile) or to the web
          // dashboard (web build).
          'platform': kIsWeb ? 'web' : 'mobile',
        },
      );

      final data = response.data;
      final payload = data is Map ? data['responseData'] : null;
      final paymentUrl = payload is Map
          ? payload['paymentUrl']?.toString()
          : null;

      if (paymentUrl == null || paymentUrl.isEmpty) {
        throw Exception(
          _extractMessage(data, fallback: 'Failed to generate payment URL.'),
        );
      }
      return paymentUrl;
    } catch (e) {
      throw Exception(
        _readErrorMessage(e, fallback: 'Failed to generate payment URL.'),
      );
    }
  }

  Future<bool> verifyKhaltiPayment({required String orderId}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.khaltiVerify,
        data: {'orderId': orderId},
      );

      final data = response.data;
      final payload = data is Map ? data['responseData'] : null;
      return payload is Map ? payload['verified'] == true : false;
    } catch (e) {
      throw Exception(
        _readErrorMessage(e, fallback: 'Failed to verify Khalti payment.'),
      );
    }
  }

  Future<Map<String, String>> createStripePaymentIntent({
    required double amount,
    required String orderId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.stripePaymentIntent,
        data: {'amount': amount, 'orderId': orderId},
      );

      final data = response.data;
      final payload = data is Map ? data['responseData'] : null;
      final clientSecret = payload is Map ? payload['clientSecret']?.toString() : null;
      final paymentIntentId = payload is Map ? payload['paymentIntentId']?.toString() : null;

      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception(
          _extractMessage(data, fallback: 'Failed to create Stripe payment intent.'),
        );
      }
      return {'clientSecret': clientSecret, 'paymentIntentId': paymentIntentId ?? ''};
    } catch (e) {
      throw Exception(
        _readErrorMessage(e, fallback: 'Failed to create Stripe payment intent.'),
      );
    }
  }

  Future<bool> verifyStripePayment({required String orderId}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.stripeVerify,
        data: {'orderId': orderId},
      );

      final data = response.data;
      final payload = data is Map ? data['responseData'] : null;
      return payload is Map ? payload['verified'] == true : false;
    } catch (e) {
      throw Exception(
        _readErrorMessage(e, fallback: 'Failed to verify Stripe payment.'),
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyOrders() async {
    final response = await _apiClient.get(ApiEndpoints.myOrders);
    final data = response.data;
    final payload = data is Map<String, dynamic> ? data['responseData'] : null;
    final orders = payload is Map<String, dynamic> ? payload['orders'] : null;

    if (orders is! List) {
      return const [];
    }

    return orders
        .whereType<Map>()
        .map((order) => Map<String, dynamic>.from(order))
        .toList();
  }

  Future<Map<String, dynamic>> fetchOrderById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.orderById(id));
    final data = response.data;
    final payload = data is Map<String, dynamic> ? data['responseData'] : null;

    if (payload is! Map<String, dynamic>) {
      throw StateError('Unable to load order details');
    }
    return payload;
  }

  Future<Map<String, dynamic>> cancelOrder(String id) async {
    final response = await _apiClient.patch(ApiEndpoints.cancelOrder(id));
    final data = response.data;
    final payload = data is Map<String, dynamic> ? data['responseData'] : null;
    final order = payload is Map<String, dynamic> ? payload['order'] : null;
    if (order is! Map<String, dynamic>) {
      throw StateError('Unable to cancel order');
    }
    return order;
  }

  Future<Set<String>> fetchWishlistIds() async {
    final response = await _apiClient.get(ApiEndpoints.wishlist);
    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    final ids = payload is Map ? payload['itemIds'] : null;
    return ids is List ? ids.map((id) => id.toString()).toSet() : <String>{};
  }

  Future<bool> toggleWishlist(String id) async {
    final response = await _apiClient.patch(ApiEndpoints.wishlistItem(id));
    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    return payload is Map && payload['saved'] == true;
  }

  Future<ShopItemModel> fetchShopItemById(String id) async {
    final response = await _apiClient.get(ApiEndpoints.homeClotheById(id));
    final data = response.data;
    final payload = data is Map<String, dynamic> ? data['responseData'] : null;

    if (payload is Map<String, dynamic>) {
      return ShopItemModel.fromJson(payload);
    }

    throw Exception('Unable to load product details');
  }

  Future<List<ShopItemModel>> fetchShopItems({
    int page = 1,
    int limit = 24,
    String? search,
    String? category,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.homeClothes,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (category != null && category.trim().isNotEmpty)
          'category': category.trim(),
      },
    );

    final data = response.data;
    final payload = data is Map<String, dynamic> ? data['responseData'] : null;
    final items = payload is Map<String, dynamic> ? payload['data'] : null;

    if (items is! List) {
      return const [];
    }

    return items
        .whereType<Map>()
        .map((item) => ShopItemModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
