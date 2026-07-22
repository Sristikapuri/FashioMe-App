import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Base URL helpers for local backend development.
  // Recommended for physical device:
  // flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8089/api/v1
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8089/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8089/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'http://localhost:8089/api/v1';
    }
  }

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // =========== Auth Endpoints ===========
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authWhoami = '/auth/whoami';
  static const String authUpdate = '/auth/update';
  static const String authDelete = '/auth/delete';

  // =========== User Endpoints ===========
  static const String users = '/users';
  static String userById(String id) => '/users/$id';

  // =========== Upload Endpoints ===========
  static const String itemUploadPhoto = '/upload/upload-photo';
  static const String itemUploadVideo = '/upload/upload-video';

  // =========== Onboarding Endpoints ===========
  static const String onboardingStatus = '/onboarding/status';
  static const String onboardingComplete = '/onboarding/complete';

  // =========== Silhouette Endpoints ===========
  static const String silhouetteProfile = '/silhouette/profile';

  // =========== Home AI Endpoints ===========
  static const String homeDashboard = '/home/dashboard';
  static const String homeTrends = '/home/trends';
  static const String homeGenerateOutfit = '/home/generate-outfit';
  static const String homeAssistantChat = '/home/assistant-chat';
  static const String homeWardrobe = '/home/wardrobe';
  static const String homeWardrobeSync = '/home/wardrobe/sync';
  static const String homeGenerateProfile = '/home/generate-profile';
  static const String homeSearch = '/home/search';
  static String homeWardrobeItem(String id) => '/home/wardrobe/$id';
  static const String homeClothes = '/home/clothes';
  static String homeClotheById(String id) => '/home/clothes/$id';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String myOrders = '/orders/me';
  static const String esewaPaymentUrl = '/esewa/payment-url';
  static const String esewaVerify = '/esewa/verify';

  static String get origin {
    final uri = Uri.parse(baseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  static String resolveAssetUrl(String value) {
    if (value.isEmpty) {
      return value;
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('/')) {
      return '$origin$value';
    }

    return value;
  }
}
