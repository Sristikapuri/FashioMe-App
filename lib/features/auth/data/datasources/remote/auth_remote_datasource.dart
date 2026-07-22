import 'dart:io';
import 'package:dio/dio.dart';
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
      final responseToken =
          responseData['token'] ?? responseData['accessToken'];
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

  String _extractMessage(dynamic data, {required String fallback}) {
    if (data is Map<String, dynamic>) {
      final message = data['responseMessage'] ?? data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return fallback;
  }

  String _readErrorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      return _extractMessage(error.response?.data, fallback: fallback);
    }
    return fallback;
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
          role: user.role,
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
      role: sessionUser.role,
    );
  }

  @override
  Future<AuthModel?> whoami() async {
    final token = await _tokenService.getToken();
    if (token == null) {
      return null;
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.authWhoami,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!_isSuccessful(response.data)) {
        return null;
      }

      final userMap = _extractUserMap(response.data);
      if (userMap == null) {
        return null;
      }

      final user = AuthApiModel.fromJson(userMap);

      // Update session with fresh user data
      if (user.authId != null && user.authId!.isNotEmpty) {
        await _userSessionService.saveUser(
          SessionUser(
            userId: user.authId!,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            username: user.username,
            gender: user.gender,
            age: user.age,
            role: user.role,
          ),
        );
      }

      return AuthModel(
        authId: user.authId,
        firstName: user.firstName,
        lastName: user.lastName,
        username: user.username,
        email: user.email,
        gender: user.gender,
        age: user.age,
        role: user.role,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.authForgotPassword,
        data: {'email': email.trim().toLowerCase()},
      );

      if (!_isSuccessful(response.data)) {
        throw Exception(
          _extractMessage(
            response.data,
            fallback: 'Failed to send password reset instructions.',
          ),
        );
      }
    } catch (e) {
      throw Exception(
        _readErrorMessage(
          e,
          fallback: 'Failed to send password reset instructions.',
        ),
      );
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.authResetPassword,
        data: {
          'email': email.trim().toLowerCase(),
          'token': token.trim(),
          'password': password,
        },
      );

      if (!_isSuccessful(response.data)) {
        throw Exception(
          _extractMessage(response.data, fallback: 'Failed to reset password.'),
        );
      }
    } catch (e) {
      throw Exception(
        _readErrorMessage(e, fallback: 'Failed to reset password.'),
      );
    }
  }

  @override
  Future<bool> deleteAccount() async {
    final token = await _tokenService.getToken();
    if (token == null) {
      throw Exception('No active session found.');
    }

    try {
      final response = await _apiClient.delete(
        ApiEndpoints.authDelete,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!_isSuccessful(response.data)) {
        throw Exception(
          _extractMessage(response.data, fallback: 'Failed to delete account.'),
        );
      }

      return true;
    } catch (e) {
      throw Exception(
        _readErrorMessage(e, fallback: 'Failed to delete account.'),
      );
    }
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
    final token = await _tokenService.getToken();
    if (token == null) {
      return null;
    }

    try {
      final formData = FormData.fromMap({});

      if (firstName != null) {
        formData.fields.add(MapEntry('firstName', firstName));
      }
      if (lastName != null) formData.fields.add(MapEntry('lastName', lastName));
      if (username != null) formData.fields.add(MapEntry('username', username));
      if (gender != null) formData.fields.add(MapEntry('gender', gender));
      if (age != null) formData.fields.add(MapEntry('age', age.toString()));
      if (password != null) formData.fields.add(MapEntry('password', password));

      if (profileImage != null) {
        formData.files.add(
          MapEntry(
            'profileImage',
            await MultipartFile.fromFile(profileImage.path),
          ),
        );
      }

      final response = await _apiClient.put(
        ApiEndpoints.authUpdate,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!_isSuccessful(response.data)) {
        return null;
      }

      final userMap = _extractUserMap(response.data);
      if (userMap == null) {
        return null;
      }

      final user = AuthApiModel.fromJson(userMap);

      // Update session with fresh user data
      if (user.authId != null && user.authId!.isNotEmpty) {
        await _userSessionService.saveUser(
          SessionUser(
            userId: user.authId!,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            username: user.username,
            gender: user.gender,
            age: user.age,
            role: user.role,
          ),
        );
      }

      return AuthModel(
        authId: user.authId,
        firstName: user.firstName,
        lastName: user.lastName,
        username: user.username,
        email: user.email,
        gender: user.gender,
        age: user.age,
        role: user.role,
      );
    } catch (e) {
      return null;
    }
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
