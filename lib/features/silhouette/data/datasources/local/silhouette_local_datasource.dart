import 'dart:convert';

import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:fashio_me/features/silhouette/data/datasources/silhouette_datasource.dart';
import 'package:fashio_me/features/silhouette/data/models/silhouette_profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final silhouetteLocalDataSourceProvider = Provider<ISilhouetteDataSource>((ref) {
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

  String? _profileKey() {
    final userId = _userSessionService.getUserId();
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return 'silhouette_profile_$userId';
  }

  @override
  SilhouetteProfileModel? getProfile() {
    final key = _profileKey();
    if (key == null) {
      return null;
    }

    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return SilhouetteProfileModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool hasCompletedProfile() {
    return getProfile()?.toEntity().isComplete ?? false;
  }

  @override
  Future<void> saveProfile(SilhouetteProfileModel profile) async {
    final key = _profileKey();
    if (key == null) {
      throw StateError('A logged in user is required before saving silhouette data.');
    }
    await _prefs.setString(key, jsonEncode(profile.toJson()));
  }

  @override
  Future<void> clearProfile() async {
    final key = _profileKey();
    if (key == null) {
      return;
    }
    await _prefs.remove(key);
  }
}

