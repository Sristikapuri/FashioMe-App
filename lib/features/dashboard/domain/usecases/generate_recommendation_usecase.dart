import 'package:fashio_me/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fashio_me/features/dashboard/domain/repositories/dashboard_home_repository.dart';

class GenerateRecommendationUsecase {
  const GenerateRecommendationUsecase(this._repository);

  final IDashboardHomeRepository _repository;

  Future<DashboardRecommendation?> call({
    required String occasion,
    required DashboardProfileData profileData,
    required Map<String, int> preferenceScores,
  }) async {
    try {
      return await _repository.generateOutfit(
        occasion: occasion,
        profileData: profileData,
        preferenceScores: preferenceScores,
      );
    } catch (_) {
      return null;
    }
  }
}
