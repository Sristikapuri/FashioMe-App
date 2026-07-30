import 'package:fashio_me/features/style_archive/domain/entities/style_archive_entry.dart';
import 'package:fashio_me/features/style_archive/domain/repositories/style_archive_repository.dart';

class GetStyleArchiveUsecase {
  const GetStyleArchiveUsecase(this._repository);
  final IStyleArchiveRepository _repository;

  Future<List<StyleArchiveEntry>> call() => _repository.fetchStyleArchive();
}
