import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/features/dashboard/data/datasources/dashboard_upload_datasource.dart';
import 'package:fashio_me/features/dashboard/data/datasources/remote/dashboard_upload_remote_datasource.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_upload_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardUploadRepositoryProvider = Provider<IDashboardUploadRepository>((
  ref,
) {
  return DashboardUploadRepositoryImpl(
    remoteDataSource: ref.read(dashboardUploadRemoteDataSourceProvider),
  );
});

class DashboardUploadRepositoryImpl implements IDashboardUploadRepository {
  DashboardUploadRepositoryImpl({
    required IDashboardUploadDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final IDashboardUploadDataSource _remoteDataSource;

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadItemPhoto({
    required String imagePath,
    required String fileName,
    void Function(int sentBytes, int totalBytes)? onSendProgress,
  }) async {
    try {
      final response = await _remoteDataSource.uploadItemPhoto(
        imagePath: imagePath,
        fileName: fileName,
        onSendProgress: onSendProgress,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Right(data);
      }
      if (data is Map) {
        return Right(Map<String, dynamic>.from(data));
      }
      return const Right(<String, dynamic>{});
    } on DioException catch (e) {
      return Left(
        ApiFailure(
          statusCode: e.response?.statusCode,
          message: e.message ?? 'Upload failed.',
        ),
      );
    } catch (e) {
      return Left(ApiFailure(message: e.toString()));
    }
  }
}
