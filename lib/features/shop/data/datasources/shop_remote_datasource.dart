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
            .map((entry) => {
                  'clotheId': entry.key,
                  'quantity': entry.value,
                })
            .toList(),
      },
    );
  }

  Future<void> placeOrder({required String shippingAddress}) async {
    await _apiClient.post(
      ApiEndpoints.orders,
      data: {
        'shippingAddress': shippingAddress,
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchMyOrders() async {
    final response = await _apiClient.get(ApiEndpoints.myOrders);
    final data = response.data;
    final payload = data is Map<String, dynamic> ? data['responseData'] : null;
    final orders = payload is Map<String, dynamic> ? payload['orders'] : null;

    if (orders is! List) {
      return const [];
    }

    return orders.whereType<Map>().map((order) => Map<String, dynamic>.from(order)).toList();
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
        if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
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
