import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/core/services/storage/storage_service.dart';
import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main.dart');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StorageService(prefs: prefs);
});

final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return UserSessionService(storageService: storageService);
});
