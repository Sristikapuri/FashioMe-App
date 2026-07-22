import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/features/shop/data/models/shop_item_model.dart';

final shopRemoteDataSourceProvider = Provider<ShopRemoteDataSource>((ref) {
  return ShopRemoteDataSource(apiClient: ref.read(apiClientProvider));
});

class ShopRemoteDataSource {
  ShopRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, int>> fetchCartItems() async {
    final response = await _apiClient.get(ApiEndpoints.cart);
    final data = response.data;
    final payload = data is Map<String, dynamic> ? data['responseData'] : null;
    final items = payload is Map<String, dynamic> ? payload['items'] : null;

    if (items is! List) {
      return {};
    }

    final bag = <String, int>{};
    for (final item in items.whereType<Map>()) {
      final clothe = item['clothe'];
      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      if (clothe is Map && quantity > 0) {
        final id = (clothe['_id'] ?? clothe['id'] ?? '').toString();
        if (id.isNotEmpty) {
          bag[id] = quantity;
        }
      }
    }

    return bag;
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
      data: {
        'amount': amount,
        'orderId': orderId,
        'productCode': productCode,
      },
    );

    final data = response.data;
    final payload = data is Map ? data['responseData'] : null;
    return payload is Map ? payload['verified'] == true : false;
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
