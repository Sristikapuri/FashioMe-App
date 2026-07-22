import 'package:equatable/equatable.dart';

import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';

class SilhouetteFlowState extends Equatable {
  const SilhouetteFlowState({
    required this.currentStep,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.buildType,
    required this.bodyShape,
    required this.skinTone,
    this.faceShape,
    this.portraitPath,
    this.isSaving = false,
  });

  const SilhouetteFlowState.initial()
    : currentStep = 0,
      gender = 'female',
      heightCm = 172,
      weightKg = 64,
      buildType = 'athletic',
      bodyShape = 'curvy',
      skinTone = 'warm',
      faceShape = null,
      portraitPath = null,
      isSaving = false;

  final int currentStep;
  final String gender;
  final int heightCm;
  final int weightKg;
  final String buildType;
  final String bodyShape;
  final String skinTone;
  final String? faceShape;
  final String? portraitPath;
  final bool isSaving;

  SilhouetteProfile toProfile() {
    return SilhouetteProfile(
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      buildType: buildType,
      bodyShape: bodyShape,
      skinTone: skinTone,
      faceShape: faceShape,
      portraitPath: portraitPath,
    );
  }

  bool get canFinishStepOne {
    return gender.isNotEmpty &&
        heightCm > 0 &&
        weightKg > 0 &&
        buildType.isNotEmpty &&
        bodyShape.isNotEmpty;
  }

  bool get canFinishStepTwo => skinTone.isNotEmpty;

  bool get canFinishStepThree {
    return (faceShape?.isNotEmpty ?? false) ||
        (portraitPath?.isNotEmpty ?? false);
  }

  SilhouetteFlowState copyWith({
    int? currentStep,
    String? gender,
    int? heightCm,
    int? weightKg,
    String? buildType,
    String? bodyShape,
    String? skinTone,
    String? faceShape,
    String? portraitPath,
    bool? isSaving,
    bool clearFaceShape = false,
    bool clearPortraitPath = false,
  }) {
    return SilhouetteFlowState(
      currentStep: currentStep ?? this.currentStep,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      buildType: buildType ?? this.buildType,
      bodyShape: bodyShape ?? this.bodyShape,
      skinTone: skinTone ?? this.skinTone,
      faceShape: clearFaceShape ? null : (faceShape ?? this.faceShape),
      portraitPath: clearPortraitPath
          ? null
          : (portraitPath ?? this.portraitPath),
      isSaving: isSaving ?? this.isSaving,
    );
  }

  factory SilhouetteFlowState.fromProfile(SilhouetteProfile profile) {
    return SilhouetteFlowState(
      currentStep: 0,
      gender: profile.gender,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      buildType: profile.buildType,
      bodyShape: profile.bodyShape,
      skinTone: profile.skinTone,
      faceShape: profile.faceShape,
      portraitPath: profile.portraitPath,
      isSaving: false,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    gender,
    heightCm,
    weightKg,
    buildType,
    bodyShape,
    skinTone,
    faceShape,
    portraitPath,
    isSaving,
  ];
}
