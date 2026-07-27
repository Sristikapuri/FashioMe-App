class Clothe {
  final String name;
  final String? imageUrl;
  final num? price;
  final String? category;

  Clothe({
    required this.name,
    this.imageUrl,
    this.price,
    this.category,
  });
}

class Review {
  final String id;
  final String clotheId;
  final String userId;
  final int rating;
  final String? title;
  final String comment;
  final bool verifiedPurchase;
  final String createdAt;
  final String updatedAt;
  final Clothe? clothe;

  Review({
    required this.id,
    required this.clotheId,
    required this.userId,
    required this.rating,
    this.title,
    required this.comment,
    required this.verifiedPurchase,
    required this.createdAt,
    required this.updatedAt,
    this.clothe,
  });
}
