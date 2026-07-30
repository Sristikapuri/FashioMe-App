import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/features/style_archive/domain/entities/style_archive_entry.dart';

class StyleArchiveEntryModel {
  const StyleArchiveEntryModel({
    required this.weekKey,
    required this.day,
    required this.occasion,
    required this.title,
    required this.outfit,
    required this.imageUrl,
    required this.explanation,
    required this.paletteLabels,
    required this.wardrobeItemsUsed,
    this.updatedAt,
  });

  final String weekKey;
  final String day;
  final String occasion;
  final String title;
  final String outfit;
  final String imageUrl;
  final String explanation;
  final List<String> paletteLabels;
  final List<String> wardrobeItemsUsed;
  final DateTime? updatedAt;

  factory StyleArchiveEntryModel.fromJson(Map<String, dynamic> json) {
    return StyleArchiveEntryModel(
      weekKey: (json['weekKey'] ?? '').toString(),
      day: (json['day'] ?? '').toString(),
      occasion: (json['occasion'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      outfit: (json['outfit'] ?? '').toString(),
      imageUrl: ApiEndpoints.resolveAssetUrl(
        (json['imageUrl'] ?? '').toString(),
      ),
      explanation: (json['explanation'] ?? '').toString(),
      paletteLabels: List<String>.from(json['paletteLabels'] ?? const []),
      wardrobeItemsUsed: List<String>.from(
        json['wardrobeItemsUsed'] ?? const [],
      ),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    );
  }

  StyleArchiveEntry toEntity() {
    return StyleArchiveEntry(
      weekKey: weekKey,
      day: day,
      occasion: occasion,
      title: title,
      outfit: outfit,
      imageUrl: imageUrl,
      explanation: explanation,
      paletteLabels: paletteLabels,
      wardrobeItemsUsed: wardrobeItemsUsed,
      updatedAt: updatedAt,
    );
  }
}
