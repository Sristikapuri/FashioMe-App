import 'package:fashio_me/features/style_archive/domain/entities/style_archive_entry.dart';

abstract interface class IStyleArchiveRepository {
  Future<List<StyleArchiveEntry>> fetchStyleArchive();

  Future<List<StyleArchiveEntry>> saveEntry({
    required String weekKey,
    required String day,
    required String occasion,
    String title,
    String outfit,
    String imageUrl,
    String explanation,
    List<String> paletteLabels,
    List<String> wardrobeItemsUsed,
  });
}
