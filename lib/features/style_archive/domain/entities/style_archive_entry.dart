class StyleArchiveEntry {
  const StyleArchiveEntry({
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
}
