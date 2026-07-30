import 'package:fashio_me/core/api/api_endpoints.dart';

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
  final ReviewerInfo? reviewer;

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
    this.reviewer,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // clotheId/userId come back as plain string ids on create/update, but as
    // populated objects ({_id, ...}) on the list endpoints.
    final rawClotheId = json['clotheId'];
    final rawUserId = json['userId'];

    final clotheMap = rawClotheId is Map ? Map<String, dynamic>.from(rawClotheId) : null;
    final userMap = rawUserId is Map ? Map<String, dynamic>.from(rawUserId) : null;

    return ReviewModel(
      id: json['_id']?.toString() ?? json['id'] ?? '',
      clotheId: clotheMap != null
          ? (clotheMap['_id']?.toString() ?? '')
          : (rawClotheId?.toString() ?? ''),
      userId: userMap != null
          ? (userMap['_id']?.toString() ?? '')
          : (rawUserId?.toString() ?? ''),
      rating: (json['rating'] is int ? json['rating'] : (json['rating'] as num).toInt()),
      title: json['title'],
      comment: json['comment'] ?? '',
      verifiedPurchase: json['verifiedPurchase'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      clothe: clotheMap != null
          ? ClotheInfo.fromJson(clotheMap)
          : (json['clothe'] != null ? ClotheInfo.fromJson(json['clothe']) : null),
      reviewer: userMap != null ? ReviewerInfo.fromJson(userMap) : null,
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
      'reviewer': reviewer?.toJson(),
    };
  }
}

class ReviewerInfo {
  final String? firstName;
  final String? lastName;
  final String? profileImage;

  ReviewerInfo({this.firstName, this.lastName, this.profileImage});

  String get displayName {
    final name = [firstName, lastName].where((n) => n != null && n.isNotEmpty).join(' ');
    return name.isEmpty ? 'Anonymous' : name;
  }

  factory ReviewerInfo.fromJson(Map<String, dynamic> json) {
    return ReviewerInfo(
      firstName: json['firstName'],
      lastName: json['lastName'],
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'profileImage': profileImage,
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
    final rawImageUrl = json['imageUrl'] as String?;
    return ClotheInfo(
      name: json['name'] ?? '',
      imageUrl: (rawImageUrl == null || rawImageUrl.isEmpty)
          ? null
          : ApiEndpoints.resolveAssetUrl(rawImageUrl),
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
