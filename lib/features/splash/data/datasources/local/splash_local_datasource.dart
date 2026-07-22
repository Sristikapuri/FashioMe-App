import 'package:fashio_me/core/providers/storage_provider.dart';
import 'package:fashio_me/core/services/storage/storage_service.dart';
import 'package:fashio_me/features/splash/data/datasources/splash_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashLocalDataSourceProvider = Provider<ISplashDataSource>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return SplashLocalDataSource(storageService: storageService);
});

class SplashLocalDataSource implements ISplashDataSource {
  final StorageService _storageService;

  SplashLocalDataSource({required StorageService storageService})
    : _storageService = storageService;

  @override
  bool isLoggedIn() {
    return _storageService.getBool('is_logged_in') ?? false;
  }

  @override
  bool hasCompletedOnboarding() {
    return _storageService.getBool('onboarding_completed') ?? false;
  }
}
