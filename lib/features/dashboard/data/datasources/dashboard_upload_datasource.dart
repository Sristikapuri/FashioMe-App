import 'package:dio/dio.dart';

abstract interface class IDashboardUploadDataSource {
  Future<Response<dynamic>> uploadItemPhoto({
    required String imagePath,
    required String fileName,
    void Function(int sentBytes, int totalBytes)? onSendProgress,
  });
}
