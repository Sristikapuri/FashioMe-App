import 'dart:io';
import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:fashio_me/features/auth/data/datasources/auth_datasource.dart';
import 'package:fashio_me/features/auth/data/models/auth_model.dart';
import 'package:fashio_me/features/auth/data/models/auth_hive_model.dart';
import 'package:fashio_me/features/auth/data/services/hive_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authLocalDatasourceProvider = Provider<IAuthDataSource>((ref) {
  return AuthLocalDataSource(
    hiveService: ref.read(hiveServiceProvider),
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

class AuthLocalDataSource implements IAuthDataSource {
  final HiveService _hiveService;
  final UserSessionService _userSessionService;

  AuthLocalDataSource({
    required HiveService hiveService,
    required UserSessionService userSessionService,
  }) : _hiveService = hiveService,
       _userSessionService = userSessionService;

  @override
  Future<bool> register(AuthModel model) async {
    final authId = (model.authId != null && model.authId!.isNotEmpty)
        ? model.authId!
        : DateTime.now().millisecondsSinceEpoch.toString();
    final authHiveModel = AuthHiveModel(
      authId: authId,
      fullName: model.fullName,
      email: model.email.trim().toLowerCase(),
      password: model.password ?? '',
    );
    await _hiveService.registerUser(authHiveModel);

    final nameParts = model.fullName.split(' ');
    final firstName = model.firstName.isNotEmpty
        ? model.firstName
        : (nameParts.isNotEmpty ? nameParts.first : '');
    final lastName = model.lastName.isNotEmpty
        ? model.lastName
        : (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
    final username = model.username.isNotEmpty
        ? model.username
        : model.email.split('@').first;

    await _userSessionService.saveUser(
      SessionUser(
        userId: authId,
        email: model.email.trim().toLowerCase(),
        firstName: firstName,
        lastName: lastName,
        username: username,
        gender: model.gender,
        age: model.age,
      ),
    );
    return true;
  }

  @override
  Future<AuthModel?> login(String email, String password) async {
    final authHiveModel = await _hiveService.loginUser(email, password);
    if (authHiveModel == null) return null;

    final nameParts = authHiveModel.fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final username = authHiveModel.email.split('@').first;

    await _userSessionService.saveUser(
      SessionUser(
        userId: authHiveModel.authId,
        email: authHiveModel.email,
        firstName: firstName,
        lastName: lastName,
        username: username,
      ),
    );

    return AuthModel(
      authId: authHiveModel.authId,
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: authHiveModel.email,
      password: authHiveModel.password,
    );
  }

  @override
  Future<AuthModel?> getCurrentUser() async {
    final authId = _userSessionService.getUserId();
    if (authId == null) return null;

    final authHiveModel = await _hiveService.getCurrentUser(authId);
    if (authHiveModel == null) return null;

    return AuthModel.fromJson({
      'authId': authHiveModel.authId,
      'fullName': authHiveModel.fullName,
      'email': authHiveModel.email,
      'password': authHiveModel.password,
    });
  }

  @override
  Future<AuthModel?> whoami() async {
    return getCurrentUser();
  }

  @override
  Future<void> forgotPassword(String email) async {
    final exists = await _hiveService.isEmailExist(email);
    if (!exists) {
      throw Exception('No account found for that email.');
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    throw Exception(
      'Password reset is only supported with the backend service.',
    );
  }

  @override
  Future<bool> deleteAccount() async {
    throw Exception(
      'Account deletion is only supported with the backend service.',
    );
  }

  @override
  Future<AuthModel?> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? gender,
    int? age,
    File? profileImage,
    String? password,
  }) async {
    final authId = _userSessionService.getUserId();
    if (authId == null) return null;

    final authHiveModel = await _hiveService.getCurrentUser(authId);
    if (authHiveModel == null) return null;

    final updatedModel = AuthHiveModel(
      authId: authId,
      fullName: '${firstName ?? ''} ${lastName ?? ''}'.trim().isNotEmpty
          ? '${firstName ?? ''} ${lastName ?? ''}'.trim()
          : authHiveModel.fullName,
      email: authHiveModel.email,
      password: password ?? authHiveModel.password,
    );

    await _hiveService.registerUser(updatedModel);

    return AuthModel(
      authId: authId,
      firstName: firstName ?? authHiveModel.fullName.split(' ').first,
      lastName:
          lastName ??
          (authHiveModel.fullName.split(' ').length > 1
              ? authHiveModel.fullName.split(' ').sublist(1).join(' ')
              : ''),
      username: username ?? authId,
      email: authHiveModel.email,
      gender: gender,
      age: age?.toString(),
    );
  }

  @override
  Future<bool> logout() async {
    await _userSessionService.clearSession();
    await _userSessionService.clearOnboarding();
    return true;
  }

  @override
  Future<bool> isEmailExists(String email) async {
    return await _hiveService.isEmailExist(email);
  }

  @override
  Future<void> saveSession(String authId) {
    return _userSessionService.saveSession(authId);
  }

  @override
  bool isLoggedIn() {
    return _userSessionService.isLoggedIn();
  }

  @override
  Future<void> completeOnboarding() {
    return _userSessionService.completeOnboarding();
  }

  @override
  bool hasCompletedOnboarding() {
    return _userSessionService.hasCompletedOnboarding();
  }
}
