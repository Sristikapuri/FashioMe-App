import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fashio_me/features/auth/data/services/hive_table_constant.dart';
import 'package:fashio_me/features/auth/data/models/auth_hive_model.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${HiveTableConstant.dbName}';
    Hive.init(path);
    _registerAdapter();
    await openBoxes();
  }

  void _registerAdapter() {
    if (!Hive.isAdapterRegistered(HiveTableConstant.authTypeId)) {
      Hive.registerAdapter(AuthHiveModelAdapter());
    }
  }

  Future<void> openBoxes() async {
    await Hive.openBox<AuthHiveModel>(HiveTableConstant.authTable);
  }

  Future<void> close() async {
    await Hive.close();
  }

  Box<AuthHiveModel> get _authBox =>
      Hive.box<AuthHiveModel>(HiveTableConstant.authTable);

  Future<AuthHiveModel> registerUser(AuthHiveModel model) async {
    await _authBox.put(model.authId, model);
    return model;
  }

  Future<AuthHiveModel?> loginUser(String email, String password) async {
    final auths = _authBox.values.where(
      (auth) => auth.email == email && auth.password == password,
    );
    return auths.isEmpty ? null : auths.first;
  }

  Future<void> logoutUser() async {}

  AuthHiveModel? getCurrentUser(String authId) {
    return _authBox.get(authId);
  }

  bool isEmailExist(String email) {
    return _authBox.values.any((auth) => auth.email == email);
  }
}
