import 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:fashio_me/core/services/storage/storage_service.dart';
import 'package:fashio_me/core/services/storage/token_service.dart';
import 'package:fashio_me/core/providers/shared_prefs_provider.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs: prefs);
});

final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService();
});
