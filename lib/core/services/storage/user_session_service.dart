import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return UserSessionService(prefs: prefs);
});

class SessionUser {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String? gender;
  final String? age;
  final String? role;
  final String? profileImage;

  const SessionUser({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.gender,
    this.age,
    this.role,
    this.profileImage,
  });
}

class UserSessionService {
  final SharedPreferences _prefs;

  UserSessionService({required SharedPreferences prefs}) : _prefs = prefs;

  // Session keys
  static const String _keyUserId = 'user_id';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyOnboardingVersion = 'onboarding_version';
  static const int _currentOnboardingVersion = 1;
  static const String _keyFirstName = 'first_name';
  static const String _keyLastName = 'last_name';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';
  static const String _keyGender = 'gender';
  static const String _keyAge = 'age';
  static const String _keyRole = 'role';
  static const String _keyProfileImage = 'profile_image';

  // Save user session
  Future<void> saveSession(String userId) async {
    await _prefs.setString(_keyUserId, userId);
    await _prefs.setBool(_keyIsLoggedIn, true);
  }

  Future<void> saveUser(SessionUser user) async {
    if (user.userId.isEmpty) {
      throw ArgumentError('User id is required to save session.');
    }

    await saveSession(user.userId);
    await _prefs.setString(_keyFirstName, user.firstName);
    await _prefs.setString(_keyLastName, user.lastName);
    await _prefs.setString(_keyUsername, user.username);
    await _prefs.setString(_keyEmail, user.email);

    if (user.gender != null && user.gender!.isNotEmpty) {
      await _prefs.setString(_keyGender, user.gender!);
    } else {
      await _prefs.remove(_keyGender);
    }

    if (user.age != null && user.age!.isNotEmpty) {
      await _prefs.setString(_keyAge, user.age!);
    } else {
      await _prefs.remove(_keyAge);
    }

    if (user.role != null && user.role!.isNotEmpty) {
      await _prefs.setString(_keyRole, user.role!);
    } else {
      await _prefs.remove(_keyRole);
    }

    if (user.profileImage != null && user.profileImage!.isNotEmpty) {
      await _prefs.setString(_keyProfileImage, user.profileImage!);
    } else {
      await _prefs.remove(_keyProfileImage);
    }
  }

  SessionUser? getCurrentUser() {
    final userId = getUserId();
    final email = _prefs.getString(_keyEmail);

    if (userId == null || email == null || email.isEmpty) {
      return null;
    }

    return SessionUser(
      userId: userId,
      firstName: _prefs.getString(_keyFirstName) ?? '',
      lastName: _prefs.getString(_keyLastName) ?? '',
      username: _prefs.getString(_keyUsername) ?? '',
      email: email,
      gender: _prefs.getString(_keyGender),
      age: _prefs.getString(_keyAge),
      role: _prefs.getString(_keyRole),
      profileImage: _prefs.getString(_keyProfileImage),
    );
  }

  // Get current user ID
  String? getUserId() {
    return _prefs.getString(_keyUserId);
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Clear session (logout)
  Future<void> clearSession() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyFirstName);
    await _prefs.remove(_keyLastName);
    await _prefs.remove(_keyUsername);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyGender);
    await _prefs.remove(_keyAge);
    await _prefs.remove(_keyRole);
    await _prefs.remove(_keyProfileImage);
    await _prefs.setBool(_keyIsLoggedIn, false);
  }

  // Mark onboarding as completed
  Future<void> completeOnboarding() async {
    await _prefs.setInt(_keyOnboardingVersion, _currentOnboardingVersion);
  }

  // Check if onboarding is completed
  bool hasCompletedOnboarding() {
    return _prefs.getInt(_keyOnboardingVersion) == _currentOnboardingVersion;
  }

  // Clear onboarding status
  Future<void> clearOnboarding() async {
    await _prefs.remove(_keyOnboardingVersion);
  }
}
