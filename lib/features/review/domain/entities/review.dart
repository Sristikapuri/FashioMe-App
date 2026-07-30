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

class Reviewer {
  final String? firstName;
  final String? lastName;
  final String? profileImage;

  Reviewer({this.firstName, this.lastName, this.profileImage});

  String get displayName {
    final name = [firstName, lastName].where((n) => n != null && n.isNotEmpty).join(' ');
    return name.isEmpty ? 'Anonymous' : name;
  }
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
  final Reviewer? reviewer;

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
    this.reviewer,
  });
}
