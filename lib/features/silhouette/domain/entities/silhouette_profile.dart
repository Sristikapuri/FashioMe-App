class SilhouetteProfile {
  const SilhouetteProfile({
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.buildType,
    required this.bodyShape,
    required this.skinTone,
    this.faceShape,
    this.portraitPath,
  });

  final String gender;
  final int heightCm;
  final int weightKg;
  final String buildType;
  final String bodyShape;
  final String skinTone;
  final String? faceShape;
  final String? portraitPath;

  bool get isComplete {
    final hasStepOne =
        gender.trim().isNotEmpty &&
        heightCm > 0 &&
        weightKg > 0 &&
        buildType.trim().isNotEmpty &&
        bodyShape.trim().isNotEmpty;
    final hasStepTwo = skinTone.trim().isNotEmpty;
    final hasStepThree =
        (faceShape?.trim().isNotEmpty ?? false) ||
        (portraitPath?.trim().isNotEmpty ?? false);

    return hasStepOne && hasStepTwo && hasStepThree;
  }

  String get toneLabel {
    switch (skinTone) {
      case 'fair':
        return 'Fair';
      case 'light':
        return 'Light';
      case 'warm':
        return 'Warm';
      case 'olive':
        return 'Olive';
      case 'deep':
        return 'Deep';
      default:
        return skinTone;
    }
  }

  String get faceShapeLabel {
    switch (faceShape) {
      case 'oval':
        return 'Oval';
      case 'square':
        return 'Square';
      case 'round':
        return 'Round';
      case 'heart':
        return 'Heart';
      default:
        return faceShape ?? 'Unset';
    }
  }

  SilhouetteProfile copyWith({
    String? gender,
    int? heightCm,
    int? weightKg,
    String? buildType,
    String? bodyShape,
    String? skinTone,
    String? faceShape,
    String? portraitPath,
    bool clearFaceShape = false,
    bool clearPortraitPath = false,
  }) {
    return SilhouetteProfile(
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      buildType: buildType ?? this.buildType,
      bodyShape: bodyShape ?? this.bodyShape,
      skinTone: skinTone ?? this.skinTone,
      faceShape: clearFaceShape ? null : (faceShape ?? this.faceShape),
      portraitPath: clearPortraitPath ? null : (portraitPath ?? this.portraitPath),
    );
  }
}
