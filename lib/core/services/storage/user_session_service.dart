import 'package:fashio_me/core/services/storage/storage_service.dart';

class UserSessionService {
  final StorageService _storageService;

  UserSessionService({required StorageService storageService})
      : _storageService = storageService;

  // Session keys
  static const String _keyUserId = 'user_id';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyOnboardingCompleted = 'onboarding_completed';

  // Save user session
  Future<void> saveSession(String userId) async {
    await _storageService.setString(_keyUserId, userId);
    await _storageService.setBool(_keyIsLoggedIn, true);
  }

  // Get current user ID
  String? getUserId() {
    return _storageService.getString(_keyUserId);
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _storageService.getBool(_keyIsLoggedIn) ?? false;
  }

  // Clear session (logout)
  Future<void> clearSession() async {
    await _storageService.remove(_keyUserId);
    await _storageService.setBool(_keyIsLoggedIn, false);
  }

  // Mark onboarding as completed
  Future<void> completeOnboarding() async {
    await _storageService.setBool(_keyOnboardingCompleted, true);
  }

  // Check if onboarding is completed
  bool hasCompletedOnboarding() {
    return _storageService.getBool(_keyOnboardingCompleted) ?? false;
  }

  // Clear onboarding status
  Future<void> clearOnboarding() async {
    await _storageService.remove(_keyOnboardingCompleted);
  }
}
