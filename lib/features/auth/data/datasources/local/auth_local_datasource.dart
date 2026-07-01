import 'dart:io';
import 'package:fashio_me/core/services/hive/hive_service.dart';
import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:fashio_me/features/auth/data/datasources/auth_datasource.dart';
import 'package:fashio_me/features/auth/data/models/auth_model.dart';
import 'package:fashio_me/features/auth/data/models/auth_hive_model.dart';
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
  })  : _hiveService = hiveService,
        _userSessionService = userSessionService;

  @override
  Future<bool> register(AuthModel model) async {
    final authId = DateTime.now().millisecondsSinceEpoch.toString();
    final authHiveModel = AuthHiveModel(
      authId: authId,
      fullName: model.fullName,
      email: model.email,
      password: model.password ?? '',
    );
    await _hiveService.registerUser(authHiveModel);
    // Save session after registration
    await saveSession(authId);
    return true;
  }

  @override
  Future<AuthModel?> login(String email, String password) async {
    final authHiveModel = await _hiveService.loginUser(email, password);
    if (authHiveModel == null) return null;
    
    // Save session after successful login
    await saveSession(authHiveModel.authId);
    
    return AuthModel.fromJson({
      'authId': authHiveModel.authId,
      'fullName': authHiveModel.fullName,
      'email': authHiveModel.email,
      'password': authHiveModel.password,
    });
  }

  @override
  Future<AuthModel?> getCurrentUser() async {
    final authId = _userSessionService.getUserId();
    if (authId == null) return null;
    
    final authHiveModel = _hiveService.getCurrentUser(authId);
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

    final authHiveModel = _hiveService.getCurrentUser(authId);
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
      lastName: lastName ?? (authHiveModel.fullName.split(' ').length > 1 ? authHiveModel.fullName.split(' ').sublist(1).join(' ') : ''),
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
    return _hiveService.isEmailExist(email);
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
