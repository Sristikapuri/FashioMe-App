import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fashio_me/features/auth/data/services/hive_table_constant.dart';
import 'package:fashio_me/features/auth/data/models/auth_hive_model.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapter();
    await openBoxes();
  }

  void _registerAdapter() {
    if (!Hive.isAdapterRegistered(HiveTableConstant.authTypeId)) {
      Hive.registerAdapter(AuthHiveModelAdapter());
    }
  }

  Future<void> openBoxes() async {
    _registerAdapter();
    if (!Hive.isBoxOpen(HiveTableConstant.authTable)) {
      await Hive.openBox<AuthHiveModel>(HiveTableConstant.authTable);
    }
  }

  Future<void> close() async {
    await Hive.close();
  }

  Future<Box<AuthHiveModel>> _getAuthBox() async {
    _registerAdapter();
    if (!Hive.isBoxOpen(HiveTableConstant.authTable)) {
      return await Hive.openBox<AuthHiveModel>(HiveTableConstant.authTable);
    }
    return Hive.box<AuthHiveModel>(HiveTableConstant.authTable);
  }

  Future<AuthHiveModel> registerUser(AuthHiveModel model) async {
    final box = await _getAuthBox();
    await box.put(model.authId, model);
    return model;
  }

  Future<AuthHiveModel?> loginUser(String email, String password) async {
    final box = await _getAuthBox();
    final cleanEmail = email.trim().toLowerCase();
    final auths = box.values.where(
      (auth) =>
          auth.email.trim().toLowerCase() == cleanEmail &&
          auth.password == password,
    );
    return auths.isEmpty ? null : auths.first;
  }

  Future<void> logoutUser() async {}

  Future<AuthHiveModel?> getCurrentUser(String authId) async {
    final box = await _getAuthBox();
    return box.get(authId);
  }

  Future<bool> isEmailExist(String email) async {
    final box = await _getAuthBox();
    final cleanEmail = email.trim().toLowerCase();
    return box.values.any(
      (auth) => auth.email.trim().toLowerCase() == cleanEmail,
    );
  }
}
