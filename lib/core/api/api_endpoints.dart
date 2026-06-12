import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiEndpoints {
  ApiEndpoints._();

  // Base URL helpers for local backend development.
  // For Android Emulator use: 'http://10.0.2.2:8089/api/v1'
  // For iOS Simulator use: 'http://localhost:8089/api/v1'
  // For Physical Device use your computer's IP: 'http://192.168.x.x:8089/api/v1'

  static const bool isPhysicalDevice = false;
  static const String compIpAddress = '192.168.1.1'; // replace with PC IP

  static String get baseUrl {
    if (isPhysicalDevice) {
      return 'http://$compIpAddress:8089/api/v1';
    }
    //  if android
    if (kIsWeb) {
      return 'http://localhost:8089/api/v1';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8089/api/v1';
    } else if (Platform.isIOS) {
      return 'http://localhost:8089/api/v1';
    } else {
      return 'http://localhost:8089/api/v1';
    }
  }

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // =========== Batch Endpoints ===========
  static const String batches = '/batches';
  static String batchById(String id) => '/batches/$id';

  // =========== Category Endpoints ===========
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';

  // =========== User Endpoints ===========
  static const String users = '/users';
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static String userById(String id) => '/users/$id';
  static String userPhoto(String id) => '/users/$id/photo';

  // =========== Item Endpoints ===========
  static const String items = '/items';
  static String itemById(String id) => '/items/$id';
  static String itemClaim(String id) => '/items/$id/claim';

  static String itemUploadPhoto = '/items/upload-photo';
  static String itemUploadVideo = '/items/upload-video';

  // =========== Comment Endpoints ===========
  static const String comments = '/comments';
  static String commentById(String id) => '/comments/$id';
  static String commentsByItem(String itemId) => '/comments/item/$itemId';
  static String commentLike(String id) => '/comments/$id/like';
}
