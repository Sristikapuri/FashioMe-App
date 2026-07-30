import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashio_me/core/api/api_endpoints.dart';
import 'package:fashio_me/core/navigation/app_navigator.dart';
import 'package:fashio_me/core/providers/storage_provider.dart';
import 'package:fashio_me/core/services/storage/token_service.dart';
import 'package:fashio_me/features/auth/presentation/pages/login_page.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';


final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenService: ref.read(tokenServiceProvider));
});

class ApiClient {
  late final Dio _dio;
  final TokenService _tokenService;

  ApiClient({required TokenService tokenService})
    : _tokenService = tokenService {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiEndpoints.connectionTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );


    _dio.interceptors.add(_AuthInterceptor(tokenService: _tokenService));

    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
        retryEvaluator: (error, attempt) {
          return error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError;
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }
  }

  Dio get dio => _dio;

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> uploadFile(
    String path, {
    required FormData formData,
    Options? options,
    ProgressCallback? onSendProgress,
  }) async {
    final uploadOptions =
        options?.copyWith(
          contentType:
              options.contentType ?? Headers.multipartFormDataContentType,
        ) ??
        Options(contentType: Headers.multipartFormDataContentType);

    return _dio.post(
      path,
      data: formData,
      options: uploadOptions,
      onSendProgress: onSendProgress,
    );
  }
}

// Auth Interceptor to add JWT token to requests
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({required TokenService tokenService})
    : _tokenService = tokenService;

  final TokenService _tokenService;
  bool _isRedirectingToLogin = false;

  static final _authEndpoints = [
    ApiEndpoints.authLogin,
    ApiEndpoints.authRegister,
    ApiEndpoints.authForgotPassword,
    ApiEndpoints.authResetPassword,
  ];

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final publicEndpoints = [ApiEndpoints.authLogin];

    final isPublicGet =
        options.method == 'GET' &&
        publicEndpoints.any((endpoint) => options.path.startsWith(endpoint));

    final isAuthEndpoint =
        options.path == ApiEndpoints.authLogin ||
        options.path == ApiEndpoints.authRegister;

    if (!isPublicGet && !isAuthEndpoint) {
      final token = await _tokenService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isAuthEndpoint = _authEndpoints.any(
      (endpoint) => err.requestOptions.path == endpoint,
    );

    if (err.response?.statusCode == 401 && !isAuthEndpoint) {
      _tokenService.clearToken();
      _redirectToLogin();
    }
    handler.next(err);
  }

  void _redirectToLogin() {
    if (_isRedirectingToLogin) return;
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    _isRedirectingToLogin = true;
    navigator
        .pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        )
        .whenComplete(() => _isRedirectingToLogin = false);
  }
}
