import 'package:fashio_me/core/api/api_client.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/core/providers/storage_provider.dart';
import 'package:fashio_me/core/services/storage/token_service.dart';
import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:fashio_me/features/auth/data/datasources/auth_datasource.dart';
import 'package:fashio_me/features/auth/data/models/auth_api_model.dart';
import 'package:fashio_me/features/auth/data/models/auth_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRemoteDatasourceProvider = Provider<IAuthDataSource>((ref) {
  return AuthRemoteDatasource(
    apiClient: ref.read(apiClientProvider),
    userSessionService: ref.read(userSessionServiceProvider),
    tokenService: ref.read(tokenServiceProvider),
  );
});

class AuthRemoteDatasource implements IAuthDataSource {
  AuthRemoteDatasource({
    required ApiClient apiClient,
    required UserSessionService userSessionService,
    required TokenService tokenService,
  }) : _apiClient = apiClient,
       _userSessionService = userSessionService,
       _tokenService = tokenService;

  final ApiClient _apiClient;
  final UserSessionService _userSessionService;
  final TokenService _tokenService;

  bool _isSuccessful(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['isSuccess'] is bool) {
        return data['isSuccess'] as bool;
      }
      if (data['success'] is bool) {
        return data['success'] as bool;
      }
    }
    return true;
  }

  Map<String, dynamic>? _extractUserMap(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final candidates = [
      data['responseData'],
      data['data'],
      data['user'],
      data['result'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        final nestedUser = candidate['user'];
        if (nestedUser is Map<String, dynamic>) {
          return nestedUser;
        }
        return candidate;
      }
    }

    final looksLikeUser =
        data.containsKey('email') ||
        data.containsKey('firstName') ||
        data.containsKey('fullName');
    return looksLikeUser ? data : null;
  }

  String? _extractToken(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final directToken = data['token'] ?? data['accessToken'];
    if (directToken is String && directToken.isNotEmpty) {
      return directToken;
    }

    final responseData = data['responseData'];
    if (responseData is Map<String, dynamic>) {
      final responseToken = responseData['token'] ?? responseData['accessToken'];
      if (responseToken is String && responseToken.isNotEmpty) {
        return responseToken;
      }
    }

    final nestedData = data['data'];
    if (nestedData is Map<String, dynamic>) {
      final nestedToken = nestedData['token'] ?? nestedData['accessToken'];
      if (nestedToken is String && nestedToken.isNotEmpty) {
        return nestedToken;
      }
    }

    return null;
  }

  @override
  Future<bool> register(AuthModel model) async {
    final response = await _apiClient.post(
      ApiEndpoints.authRegister,
      data: model.toJson(),
    );

    return _isSuccessful(response.data);
  }

  @override
  Future<AuthApiModel?> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );

    if (!_isSuccessful(response.data)) {
      return null;
    }

    final userMap = _extractUserMap(response.data);
    if (userMap == null) {
      return null;
    }

    final user = AuthApiModel.fromJson(userMap);
    final authId = user.authId;
    if (authId != null && authId.isNotEmpty) {
      await _userSessionService.saveUser(
        SessionUser(
          userId: authId,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          username: user.username,
          gender: user.gender,
          age: user.age,
        ),
      );
    }

    final token = _extractToken(response.data);
    if (token != null) {
      await _tokenService.saveToken(token);
    }

    return user;
  }

  @override
  Future<AuthModel?> getCurrentUser() async {
    final sessionUser = _userSessionService.getCurrentUser();
    if (sessionUser == null) {
      return null;
    }

    return AuthModel(
      authId: sessionUser.userId,
      firstName: sessionUser.firstName,
      lastName: sessionUser.lastName,
      username: sessionUser.username,
      email: sessionUser.email,
      gender: sessionUser.gender,
      age: sessionUser.age,
    );
  }

  @override
  Future<bool> logout() async {
    await _tokenService.clearToken();
    await _userSessionService.clearSession();
    return true;
  }

  @override
  Future<bool> isEmailExists(String email) async {
    return false;
  }

  @override
  Future<void> saveSession(String authId) async {
    await _userSessionService.saveSession(authId);
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
