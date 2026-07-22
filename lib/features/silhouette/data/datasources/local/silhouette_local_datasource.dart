import 'dart:convert';

import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:fashio_me/features/silhouette/data/datasources/silhouette_datasource.dart';
import 'package:fashio_me/features/silhouette/data/models/silhouette_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final silhouetteLocalDataSourceProvider = Provider<ISilhouetteDataSource>((
  ref,
) {
  return SilhouetteLocalDataSource(
    prefs: ref.read(sharedPreferencesProvider),
    userSessionService: ref.read(userSessionServiceProvider),
  );
});

class SilhouetteLocalDataSource implements ISilhouetteDataSource {
  SilhouetteLocalDataSource({
    required SharedPreferences prefs,
    required UserSessionService userSessionService,
  }) : _prefs = prefs,
       _userSessionService = userSessionService;

  final SharedPreferences _prefs;
  final UserSessionService _userSessionService;

  String _profileKey() {
    final userId = _userSessionService.getUserId();
    if (userId != null && userId.isNotEmpty) {
      return 'silhouette_profile_$userId';
    }
    return 'silhouette_profile_guest';
  }

  @override
  SilhouetteProfileModel? getProfile() {
    final userId = _userSessionService.getUserId();
    if (userId != null && userId.isNotEmpty) {
      final userKey = 'silhouette_profile_$userId';
      final raw = _prefs.getString(userKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          return SilhouetteProfileModel.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          );
        } catch (_) {}
      }
    }

    final guestRaw = _prefs.getString('silhouette_profile_guest');
    if (guestRaw != null && guestRaw.isNotEmpty) {
      try {
        return SilhouetteProfileModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(guestRaw) as Map),
        );
      } catch (_) {}
    }

    return null;
  }

  @override
  bool hasCompletedProfile() {
    return getProfile()?.toEntity().isComplete ?? false;
  }

  @override
  Future<void> saveProfile(SilhouetteProfileModel profile) async {
    final key = _profileKey();
    await _prefs.setString(key, jsonEncode(profile.toJson()));
  }

  @override
  Future<void> clearProfile() async {
    final userId = _userSessionService.getUserId();
    if (userId != null && userId.isNotEmpty) {
      await _prefs.remove('silhouette_profile_$userId');
    }
    await _prefs.remove('silhouette_profile_guest');
  }
}
