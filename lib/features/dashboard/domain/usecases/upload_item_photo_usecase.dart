import 'package:dartz/dartz.dart';
import 'package:fashio_me/core/error/failures.dart';
import 'package:fashio_me/core/usecases/app_usecase.dart';
import 'package:fashio_me/features/dashboard/data/repositories/dashboard_upload_repository_impl.dart'
    as dashboard_upload_repo;
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_upload_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final uploadItemPhotoUsecaseProvider = Provider<UploadItemPhotoUsecase>((ref) {
  return UploadItemPhotoUsecase(
    dashboardUploadRepository:
        ref.read(dashboard_upload_repo.dashboardUploadRepositoryProvider),
  );
});

class UploadItemPhotoUsecase
    implements UsecaseWithParams<Map<String, dynamic>, UploadItemPhotoParams> {
  UploadItemPhotoUsecase({
    required IDashboardUploadRepository dashboardUploadRepository,
  }) : _dashboardUploadRepository = dashboardUploadRepository;

  final IDashboardUploadRepository _dashboardUploadRepository;

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(UploadItemPhotoParams params) {
    return _dashboardUploadRepository.uploadItemPhoto(
      imagePath: params.imagePath,
      fileName: params.fileName,
      onSendProgress: params.onSendProgress,
    );
  }
}

class UploadItemPhotoParams {
  const UploadItemPhotoParams({
    required this.imagePath,
    required this.fileName,
    this.onSendProgress,
  });

  final String imagePath;
  final String fileName;
  final void Function(int sentBytes, int totalBytes)? onSendProgress;
}

