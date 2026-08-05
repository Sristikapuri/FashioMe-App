import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final libRoot = Directory('lib');

  List<File> dartFiles(String path) => Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  String source(File file) => file.readAsStringSync();

  test('domain does not depend on data or presentation', () {
    final files = dartFiles(
      'lib/features',
    ).where((file) => file.path.contains('/domain/'));

    for (final file in files) {
      final contents = source(file);
      expect(
        contents,
        isNot(contains('/data/')),
        reason: '${file.path} imports the data layer',
      );
      expect(
        contents,
        isNot(contains('/presentation/')),
        reason: '${file.path} imports the presentation layer',
      );
    }
  });

  test('presentation view-models do not depend on data implementations', () {
    final files = dartFiles(
      'lib/features',
    ).where((file) => file.path.contains('/presentation/view_model/'));

    for (final file in files) {
      expect(
        source(file),
        isNot(contains('/data/')),
        reason: '${file.path} imports the data layer',
      );
    }
  });

  test('presentation view-models do not depend on repository contracts', () {
    final files = dartFiles(
      'lib/features',
    ).where((file) => file.path.contains('/presentation/view_model/'));
    for (final file in files) {
      expect(
        source(file),
        isNot(contains('domain/repositories/')),
        reason: '${file.path} should use domain use cases',
      );
    }
  });

  test('feature data repositories implement domain contracts', () {
    final files = dartFiles(
      'lib/features',
    ).where((file) => file.path.contains('/data/repositories/'));

    for (final file in files) {
      final contents = source(file);
      expect(
        contents,
        contains('/domain/repositories/'),
        reason: '${file.path} should depend on a domain repository contract',
      );
    }
  });

  test('application composition root exists', () {
    expect(File('${libRoot.path}/app/di/providers.dart').existsSync(), isTrue);
  });
}
