import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';

abstract interface class IDashboardUploadRepository {
  Future<Either<Failure, Map<String, dynamic>>> uploadItemPhoto({
    required String imagePath,
    required String fileName,
    void Function(int sentBytes, int totalBytes)? onSendProgress,
  });
}
