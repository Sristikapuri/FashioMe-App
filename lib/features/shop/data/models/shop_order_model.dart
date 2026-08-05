import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/features/shop/domain/entities/shop_order.dart';

class ShopOrderItemModel {
  const ShopOrderItemModel({
    required this.name,
    required this.quantity,
    this.price,
    this.imageUrl,
    this.category,
    this.color,
    this.size,
  });

  final String name;
  final int quantity;
  final double? price;
  final String? imageUrl;
  final String? category;
  final String? color;
  final String? size;

  factory ShopOrderItemModel.fromJson(Map<String, dynamic> json) {
    final clothe = json['clothe'];
    final clotheMap = clothe is Map ? Map<String, dynamic>.from(clothe) : null;
    return ShopOrderItemModel(
      name: (json['name'] ?? clotheMap?['name'] ?? json['title'] ?? 'Item')
          .toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price:
          (json['price'] as num?)?.toDouble() ??
          (clotheMap?['discountedPrice'] as num?)?.toDouble() ??
          (clotheMap?['price'] as num?)?.toDouble(),
      imageUrl: ApiEndpoints.resolveAssetUrl(
        (json['imageUrl'] ?? clotheMap?['imageUrl'] ?? '').toString(),
      ),
      category:
          json['category']?.toString() ?? clotheMap?['category']?.toString(),
      color: json['color']?.toString() ?? clotheMap?['color']?.toString(),
      size: json['size']?.toString() ?? clotheMap?['size']?.toString(),
    );
  }

  ShopOrderItem toEntity() {
    return ShopOrderItem(
      name: name,
      quantity: quantity,
      price: price,
      imageUrl: imageUrl,
      category: category,
      color: color,
      size: size,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'color': color,
        'size': size,
      };
}

class ShopOrderModel {
  const ShopOrderModel({
    required this.id,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.total,
    this.tax,
    this.paymentMethod,
    this.customerName,
    this.customerEmail,
    this.phone,
    this.shippingAddress,
    this.city,
    this.postalCode,
    this.createdAt,
    this.esewaRefId,
    this.esewaTransactionId,
  });

  final String id;
  final String status;
  final List<ShopOrderItemModel> items;
  final double subtotal;
  final double total;
  final double? tax;
  final String? paymentMethod;
  final String? customerName;
  final String? customerEmail;
  final String? phone;
  final String? shippingAddress;
  final String? city;
  final String? postalCode;
  final DateTime? createdAt;
  final String? esewaRefId;
  final String? esewaTransactionId;

  factory ShopOrderModel.fromJson(Map<String, dynamic> json) {
    final items =
        (json['items'] as List?)
            ?.whereType<Map>()
            .map(
              (item) =>
                  ShopOrderItemModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList() ??
        const <ShopOrderItemModel>[];

    return ShopOrderModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      items: items,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod']?.toString(),
      customerName: json['customerName']?.toString(),
      customerEmail: json['customerEmail']?.toString(),
      phone: json['phone']?.toString(),
      shippingAddress: json['shippingAddress']?.toString(),
      city: json['city']?.toString(),
      postalCode: json['postalCode']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      esewaRefId: json['esewaRefId']?.toString(),
      esewaTransactionId: json['esewaTransactionId']?.toString(),
    );
  }

  ShopOrder toEntity() {
    return ShopOrder(
      id: id,
      status: status,
      items: items.map((item) => item.toEntity()).toList(growable: false),
      subtotal: subtotal,
      total: total,
      tax: tax,
      paymentMethod: paymentMethod,
      customerName: customerName,
      customerEmail: customerEmail,
      phone: phone,
      shippingAddress: shippingAddress,
      city: city,
      postalCode: postalCode,
      createdAt: createdAt,
      esewaRefId: esewaRefId,
      esewaTransactionId: esewaTransactionId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'total': total,
        'tax': tax,
        'paymentMethod': paymentMethod,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'phone': phone,
        'shippingAddress': shippingAddress,
        'city': city,
        'postalCode': postalCode,
        'createdAt': createdAt?.toIso8601String(),
        'esewaRefId': esewaRefId,
        'esewaTransactionId': esewaTransactionId,
      };
}
