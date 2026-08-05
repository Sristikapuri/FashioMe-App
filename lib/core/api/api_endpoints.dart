import 'package:fashio_me/core/services/network/backend_discovery_service.dart';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    // 1. Runtime-discovered URL (set by BackendDiscoveryService on Android)
    final override = ApiConfig.overrideBaseUrl;
    if (override != null && override.isNotEmpty) return override;

    // 2. Compile-time override via --dart-define=API_BASE_URL=...
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:8089/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Default to real Mac Wi-Fi IP (192.168.1.200) instead of .local domain.
        // Android DNS cannot resolve .local natively, causing Dio connection hangs.
        // Once BackendDiscoveryService runs, ApiConfig.overrideBaseUrl takes over.
        return 'http://192.168.1.200:8089/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'http://localhost:8089/api/v1';
    }
  }

  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 5);

  // =========== Auth Endpoints ===========
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authWhoami = '/auth/whoami';
  static const String authUpdate = '/auth/update';
  static const String authDelete = '/auth/delete';

  static const String users = '/users';
  static String userById(String id) => '/users/$id';
  static const String userStyleArchive = '/users/style-archive';

  static const String itemUploadPhoto = '/upload/upload-photo';

  static const String onboardingStatus = '/onboarding/status';
  static const String onboardingComplete = '/onboarding/complete';

  static const String silhouetteProfile = '/silhouette/profile';

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
  static const String wishlist = '/users/wishlist';
  static String wishlistItem(String id) => '/users/wishlist/$id';
  static String orderById(String id) => '/orders/$id';
  static String cancelOrder(String id) => '/orders/$id/cancel';
  static const String esewaPaymentUrl = '/esewa/payment-url';
  static const String esewaVerify = '/esewa/verify';
  static const String khaltiPaymentUrl = '/khalti/payment-url';
  static const String khaltiVerify = '/khalti/verify';
  static const String stripePaymentIntent = '/stripe/payment-intent';
  static const String stripeVerify = '/stripe/verify';

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
