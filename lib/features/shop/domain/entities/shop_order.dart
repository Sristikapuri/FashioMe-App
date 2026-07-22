class ShopOrderItem {
  const ShopOrderItem({
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
}

class ShopOrder {
  const ShopOrder({
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
  final List<ShopOrderItem> items;
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
}
