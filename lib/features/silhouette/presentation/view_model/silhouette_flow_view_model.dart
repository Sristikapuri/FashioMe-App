import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fashio_me/app/di/providers.dart';
import 'package:fashio_me/core/services/media/image_picker_service.dart';
import 'package:fashio_me/features/dashboard/domain/usecases/upload_item_photo_usecase.dart';
import 'package:fashio_me/features/silhouette/presentation/state/silhouette_flow_state.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/get_silhouette_profile_usecase.dart';
import 'package:fashio_me/features/silhouette/domain/usecases/save_silhouette_profile_usecase.dart';

class SilhouetteFlowViewModel extends Notifier<SilhouetteFlowState> {
  late final GetSilhouetteProfileUsecase _getProfileUsecase;
  late final SaveSilhouetteProfileUsecase _saveProfileUsecase;
  late final UploadItemPhotoUsecase _uploadItemPhotoUsecase;
  late final ImagePickerService _imagePicker;

  @override
  SilhouetteFlowState build() {
    _imagePicker = ref.read(imagePickerServiceProvider);
    _getProfileUsecase = ref.read(getSilhouetteProfileUsecaseProvider);
    _saveProfileUsecase = ref.read(saveSilhouetteProfileUsecaseProvider);
    _uploadItemPhotoUsecase = ref.read(uploadItemPhotoUsecaseProvider);
    Future.microtask(_loadSavedProfile);
    return const SilhouetteFlowState.initial();
  }

  Future<void> _loadSavedProfile() async {
    final result = await _getProfileUsecase();
    result.fold((_) {}, (profile) {
      if (profile != null) {
        state = SilhouetteFlowState.fromProfile(profile);
      }
    });
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step.clamp(0, 2));
  }

  void nextStep() {
    goToStep(state.currentStep + 1);
  }

  void previousStep() {
    goToStep(state.currentStep - 1);
  }

  void selectGender(String gender) {
    state = state.copyWith(gender: gender);
  }

  void setHeight(double height) {
    state = state.copyWith(heightCm: height.round());
  }

  void setWeight(double weight) {
    state = state.copyWith(weightKg: weight.round());
  }

  void selectBuildType(String buildType) {
    state = state.copyWith(buildType: buildType);
  }

  void selectBodyShape(String bodyShape) {
    state = state.copyWith(bodyShape: bodyShape);
  }

  void selectSkinTone(String skinTone) {
    state = state.copyWith(skinTone: skinTone);
  }

  void selectFaceShape(String faceShape) {
    state = state.copyWith(faceShape: faceShape);
  }

  Future<bool> pickPortrait(ImageSource source) async {
    try {
      state = state.copyWith(isSaving: true);
      final pickedFile = await _imagePicker.pick(
        useCamera: source == ImageSource.camera,
      );
      if (pickedFile == null) {
        state = state.copyWith(isSaving: false);
        return false;
      }

      String portraitPath = pickedFile.path;
      try {
        final uploadedPath = await _uploadPortraitToBackend(pickedFile.path);
        if (uploadedPath != null && uploadedPath.trim().isNotEmpty) {
          portraitPath = uploadedPath.trim();
        }
      } catch (_) {
        // Fallback to local image file path if backend upload fails/offline
      }

      state = state.copyWith(portraitPath: portraitPath, isSaving: false);
      return true;
    } catch (_) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  void removePortrait() {
    state = state.copyWith(clearPortraitPath: true);
  }

  /// Returns:
  ///  1  → profile saved to backend successfully
  ///  0  → saved locally only (backend unreachable — soft warning)
  /// -1  → save failed entirely
  Future<int> saveProfile() async {
    if (!state.toProfile().isComplete) {
      return -1;
    }

    state = state.copyWith(isSaving: true);
    final result = await _saveProfileUsecase(
      SaveSilhouetteProfileParams(profile: state.toProfile()),
    );
    return result.fold(
      (_) {
        state = state.copyWith(isSaving: false);
        return -1;
      },
      (savedToBackend) {
        state = state.copyWith(isSaving: false);
        // true  = backend confirmed  → 1
        // false = local-only fallback → 0
        return savedToBackend ? 1 : 0;
      },
    );
  }

  Future<String?> _uploadPortraitToBackend(String imagePath) async {
    final fileName = imagePath.split('/').last;
    final result = await _uploadItemPhotoUsecase(
      UploadItemPhotoParams(imagePath: imagePath, fileName: fileName),
    );

    return result.fold((_) => null, _extractUploadedImageReference);
  }

  String? _extractUploadedImageReference(Map<String, dynamic> data) {
    final candidates = [
      data['fileUrl'],
      data['relativeFileUrl'],
      data['filename'],
      data['fileName'],
      data['assetName'],
      data['imageName'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    final responseData = data['responseData'];
    if (responseData is Map<String, dynamic>) {
      final nestedCandidates = [
        responseData['fileUrl'],
        responseData['relativeFileUrl'],
        responseData['filename'],
        responseData['fileName'],
        responseData['assetName'],
        responseData['imageName'],
      ];

      for (final candidate in nestedCandidates) {
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
    }

    return null;
  }
}
