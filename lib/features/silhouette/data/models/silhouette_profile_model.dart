import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';

class SilhouetteProfileModel {
  const SilhouetteProfileModel({
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

  factory SilhouetteProfileModel.fromJson(Map<String, dynamic> json) {
    return SilhouetteProfileModel(
      gender: (json['gender'] ?? '').toString(),
      heightCm: json['heightCm'] as int? ?? 172,
      weightKg: json['weightKg'] as int? ?? 64,
      buildType: (json['buildType'] ?? '').toString(),
      bodyShape: (json['bodyShape'] ?? '').toString(),
      skinTone: (json['skinTone'] ?? '').toString(),
      faceShape: json['faceShape']?.toString(),
      portraitPath: json['portraitPath']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'buildType': buildType,
      'bodyShape': bodyShape,
      'skinTone': skinTone,
      'faceShape': faceShape,
      'portraitPath': portraitPath,
    };
  }

  factory SilhouetteProfileModel.fromEntity(SilhouetteProfile entity) {
    return SilhouetteProfileModel(
      gender: entity.gender,
      heightCm: entity.heightCm,
      weightKg: entity.weightKg,
      buildType: entity.buildType,
      bodyShape: entity.bodyShape,
      skinTone: entity.skinTone,
      faceShape: entity.faceShape,
      portraitPath: entity.portraitPath,
    );
  }

  SilhouetteProfile toEntity() {
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
}

