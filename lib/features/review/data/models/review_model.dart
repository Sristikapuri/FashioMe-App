class ReviewModel {
  final String id;
  final String clotheId;
  final String userId;
  final int rating;
  final String? title;
  final String comment;
  final bool verifiedPurchase;
  final String createdAt;
  final String updatedAt;
  final ClotheInfo? clothe;

  ReviewModel({
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

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['_id']?.toString() ?? json['id'] ?? '',
      clotheId: json['clotheId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      rating: (json['rating'] is int ? json['rating'] : (json['rating'] as num).toInt()),
      title: json['title'],
      comment: json['comment'] ?? '',
      verifiedPurchase: json['verifiedPurchase'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      clothe: json['clothe'] != null ? ClotheInfo.fromJson(json['clothe']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clotheId': clotheId,
      'userId': userId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'verifiedPurchase': verifiedPurchase,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'clothe': clothe?.toJson(),
    };
  }
}

class ClotheInfo {
  final String name;
  final String? imageUrl;
  final num? price;
  final String? category;

  ClotheInfo({
    required this.name,
    this.imageUrl,
    this.price,
    this.category,
  });

  factory ClotheInfo.fromJson(Map<String, dynamic> json) {
    return ClotheInfo(
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
      price: json['price'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'category': category,
    };
  }
}
