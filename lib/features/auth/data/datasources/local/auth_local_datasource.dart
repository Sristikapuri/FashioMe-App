import 'package:fashio_me/core/services/hive/hive_service.dart';
import 'package:fashio_me/features/auth/data/datasources/auth_datasource.dart';
import 'package:fashio_me/features/auth/data/models/auth_model.dart';
import 'package:fashio_me/features/auth/data/models/auth_hive_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authLocalDataSourceProvider = Provider<IAuthDataSource>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return AuthLocalDataSource(hiveService: hiveService);
});

class AuthLocalDataSource implements IAuthDataSource {
  final HiveService _hiveService;

  AuthLocalDataSource({required HiveService hiveService})
      : _hiveService = hiveService;

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
    
    return AuthModel(
      authId: authHiveModel.authId,
      fullName: authHiveModel.fullName,
      email: authHiveModel.email,
      password: authHiveModel.password,
    );
  }

  @override
  Future<AuthModel?> getCurrentUser() async {
    final authId = _hiveService.getCurrentSession();
    if (authId == null) return null;
    
    final authHiveModel = _hiveService.getCurrentUser(authId);
    if (authHiveModel == null) return null;
    
    return AuthModel(
      authId: authHiveModel.authId,
      fullName: authHiveModel.fullName,
      email: authHiveModel.email,
      password: authHiveModel.password,
    );
  }

  @override
  Future<bool> logout() async {
    await _hiveService.clearSession();
    await _hiveService.clearOnboarding();
    return true;
  }

  @override
  Future<bool> isEmailExists(String email) async {
    return _hiveService.isEmailExist(email);
  }

  @override
  Future<void> saveSession(String authId) {
    return _hiveService.saveSession(authId);
  }

  @override
  bool isLoggedIn() {
    return _hiveService.isLoggedIn();
  }

  @override
  Future<void> completeOnboarding() {
    return _hiveService.completeOnboarding();
  }

  @override
  bool hasCompletedOnboarding() {
    return _hiveService.hasCompletedOnboarding();
  }
}
