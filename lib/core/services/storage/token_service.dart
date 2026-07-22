import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  TokenService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveToken(String token) {
    return _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() {
    return _secureStorage.read(key: _tokenKey);
  }

  Future<void> clearToken() {
    return _secureStorage.delete(key: _tokenKey);
  }
}
