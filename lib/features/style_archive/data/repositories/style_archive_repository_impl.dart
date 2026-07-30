import 'package:fashio_me/features/style_archive/data/datasources/style_archive_remote_datasource.dart';
import 'package:fashio_me/features/style_archive/domain/entities/style_archive_entry.dart';
import 'package:fashio_me/features/style_archive/domain/repositories/style_archive_repository.dart';

class StyleArchiveRepositoryImpl implements IStyleArchiveRepository {
  StyleArchiveRepositoryImpl({
    required StyleArchiveRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final StyleArchiveRemoteDataSource _remoteDataSource;

  @override
  Future<List<StyleArchiveEntry>> fetchStyleArchive() async {
    final entries = await _remoteDataSource.fetchStyleArchive();
    return entries.map((entry) => entry.toEntity()).toList(growable: false);
  }

  @override
  Future<List<StyleArchiveEntry>> saveEntry({
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
    final entries = await _remoteDataSource.saveStyleArchiveEntry(
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
    return entries.map((entry) => entry.toEntity()).toList(growable: false);
  }
}
