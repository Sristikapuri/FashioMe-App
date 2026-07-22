class ShopItem {
  const ShopItem({
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

  double get salePrice => discountedPrice ?? price;

  double get savings => price > salePrice ? price - salePrice : 0;
}
