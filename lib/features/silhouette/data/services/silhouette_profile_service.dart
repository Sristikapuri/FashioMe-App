import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/features/silhouette/data/datasources/local/silhouette_local_datasource.dart';
import 'package:fashio_me/features/silhouette/data/datasources/silhouette_datasource.dart';
import 'package:fashio_me/features/silhouette/data/models/silhouette_profile_model.dart';
import 'package:fashio_me/features/silhouette/domain/entities/silhouette_profile.dart';

/// Deprecated: use the silhouette feature's domain use cases/repository.
@Deprecated('Use silhouette domain usecases/repository instead.')
final silhouetteProfileServiceProvider = Provider<SilhouetteProfileService>(
  (ref) {
    return SilhouetteProfileService(
      localDataSource: ref.read(silhouetteLocalDataSourceProvider),
    );
  },
);

/// Deprecated compatibility adapter for older callers.
@Deprecated('Use silhouette domain usecases/repository instead.')
class SilhouetteProfileService {
  SilhouetteProfileService({required ISilhouetteDataSource localDataSource})
    : _localDataSource = localDataSource;

  final ISilhouetteDataSource _localDataSource;

  SilhouetteProfile? getProfile() {
    return _localDataSource.getProfile()?.toEntity();
  }

  bool hasCompletedProfile() {
    return _localDataSource.hasCompletedProfile();
  }

  Future<void> saveProfile(SilhouetteProfile profile) async {
    await _localDataSource.saveProfile(
      SilhouetteProfileModel.fromEntity(profile),
    );
  }

  Future<void> clearProfile() async {
    await _localDataSource.clearProfile();
  }
}
