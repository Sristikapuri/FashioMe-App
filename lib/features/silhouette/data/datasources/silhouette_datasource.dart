import 'package:fashio_me/features/silhouette/data/models/silhouette_profile_model.dart';

abstract interface class ISilhouetteDataSource {
  SilhouetteProfileModel? getProfile();
  bool hasCompletedProfile();
  Future<void> saveProfile(SilhouetteProfileModel profile);
  Future<void> clearProfile();
}
