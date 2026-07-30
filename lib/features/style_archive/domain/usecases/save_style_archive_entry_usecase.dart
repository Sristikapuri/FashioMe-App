import 'package:fashio_me/features/style_archive/domain/entities/style_archive_entry.dart';
import 'package:fashio_me/features/style_archive/domain/repositories/style_archive_repository.dart';

class SaveStyleArchiveEntryUsecase {
  const SaveStyleArchiveEntryUsecase(this._repository);
  final IStyleArchiveRepository _repository;

  Future<List<StyleArchiveEntry>> call({
    required String weekKey,
    required String day,
    required String occasion,
    String title = '',
    String outfit = '',
    String imageUrl = '',
    String explanation = '',
    List<String> paletteLabels = const [],
    List<String> wardrobeItemsUsed = const [],
  }) => _repository.saveEntry(
    weekKey: weekKey,
    day: day,
    occasion: occasion,
    title: title,
    outfit: outfit,
    imageUrl: imageUrl,
    explanation: explanation,
    paletteLabels: paletteLabels,
    wardrobeItemsUsed: wardrobeItemsUsed,
  );
}
