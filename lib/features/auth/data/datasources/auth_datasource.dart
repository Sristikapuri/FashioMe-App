import 'dart:io';
import 'package:fashio_me/features/auth/data/models/auth_model.dart';

abstract interface class IAuthDataSource {
  Future<bool> register(AuthModel model);
  Future<AuthModel?> login(String email, String password);
  Future<AuthModel?> getCurrentUser();
  Future<AuthModel?> whoami();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  });
  Future<bool> deleteAccount();
  Future<AuthModel?> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? gender,
    int? age,
    File? profileImage,
    String? password,
  });
  Future<bool> logout();
  Future<bool> isEmailExists(String email);
  Future<void> saveSession(String authId);
  bool isLoggedIn();
  Future<void> completeOnboarding();
  bool hasCompletedOnboarding();
}
