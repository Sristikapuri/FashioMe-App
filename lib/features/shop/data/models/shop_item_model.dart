import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_item.dart';

class ShopItemModel {
  const ShopItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.size,
    required this.color,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.description,
    required this.status,
    this.discountedPrice,
    this.gender,
  });

  final String id;
  final String name;
  final String category;
  final String size;
  final String color;
  final double price;
  final double? discountedPrice;
  final int stock;
  final String imageUrl;
  final String description;
  final String status;
  final String? gender;

  factory ShopItemModel.fromJson(Map<String, dynamic> json) {
    return ShopItemModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      size: (json['size'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountedPrice: (json['discountedPrice'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrl: ApiEndpoints.resolveAssetUrl(
        (json['imageUrl'] ?? '').toString(),
      ),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      gender: json['gender']?.toString(),
    );
  }

  ShopItem toEntity() {
    return ShopItem(
      id: id,
      name: name,
      category: category,
      size: size,
      color: color,
      price: price,
      discountedPrice: discountedPrice,
      stock: stock,
      imageUrl: imageUrl,
      description: description,
      status: status,
      gender: gender,
    );
  }

  double get salePrice => discountedPrice ?? price;

  double get savings => price > salePrice ? price - salePrice : 0;
}
