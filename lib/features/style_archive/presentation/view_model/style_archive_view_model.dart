import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/features/style_archive/domain/entities/style_archive_entry.dart';
import 'package:fashio_me/features/style_archive/domain/usecases/get_style_archive_usecase.dart';
import 'package:fashio_me/features/style_archive/domain/usecases/save_style_archive_entry_usecase.dart';

final styleArchiveViewModelProvider = Provider<StyleArchiveViewModel>((ref) {
  return StyleArchiveViewModel(
    getArchive: ref.read(getStyleArchiveUsecaseProvider),
    saveEntry: ref.read(saveStyleArchiveEntryUsecaseProvider),
  );
});

class StyleArchiveViewModel {
  StyleArchiveViewModel({required GetStyleArchiveUsecase getArchive, required SaveStyleArchiveEntryUsecase saveEntry})
    : _getArchive = getArchive, _saveEntry = saveEntry;
  final GetStyleArchiveUsecase _getArchive;
  final SaveStyleArchiveEntryUsecase _saveEntry;

  Future<List<StyleArchiveEntry>> fetchStyleArchive() =>
      _getArchive();

  Future<void> saveTodaysLook({
    required String weekKey,
    required String day,
    required String occasion,
    String title = '',
    String outfit = '',
    String imageUrl = '',
    String explanation = '',
    List<String> paletteLabels = const [],
    List<String> wardrobeItemsUsed = const [],
  }) async {
    if (imageUrl.trim().isEmpty) {
      return;
    }
    await _saveEntry(
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
}
