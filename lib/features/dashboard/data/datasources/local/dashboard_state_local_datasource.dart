import 'dart:convert';

import 'package:fashio_me/core/providers/shared_prefs_provider.dart';
import 'package:fashio_me/core/services/storage/user_session_service.dart';
import 'package:fashio_me/features/dashboard/data/datasources/dashboard_state_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dashboardStateLocalDataSourceProvider =
    Provider<IDashboardStateDataSource>((ref) {
      return DashboardStateLocalDataSource(
        prefs: ref.read(sharedPreferencesProvider),
        userSessionService: ref.read(userSessionServiceProvider),
      );
    });

class DashboardStateLocalDataSource implements IDashboardStateDataSource {
  DashboardStateLocalDataSource({
    required SharedPreferences prefs,
    required UserSessionService userSessionService,
  }) : _prefs = prefs,
       _userSessionService = userSessionService;

  final SharedPreferences _prefs;
  final UserSessionService _userSessionService;

  String get _storageKey {
    final userId = _userSessionService.getUserId() ?? 'guest';
    return 'dashboard_local_state_$userId';
  }

  @override
  Map<String, dynamic> read() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Future<void> write(Map<String, dynamic> payload) async {
    await _prefs.setString(_storageKey, jsonEncode(payload));
  }
}
