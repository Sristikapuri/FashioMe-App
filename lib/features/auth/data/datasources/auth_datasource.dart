import 'package:fashio_me/features/auth/data/models/auth_model.dart';

abstract interface class IAuthDataSource {
  Future<bool> register(AuthModel model);
  Future<AuthModel?> login(String email, String password);
  Future<AuthModel?> getCurrentUser();
  Future<bool> logout();
  Future<bool> isEmailExists(String email);
  Future<void> saveSession(String authId);
  bool isLoggedIn();
  Future<void> completeOnboarding();
  bool hasCompletedOnboarding();
}
