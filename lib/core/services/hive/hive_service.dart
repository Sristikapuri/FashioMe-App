import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:fashio_me/core/constants/hive_table_constant.dart';
import 'package:fashio_me/features/auth/data/models/auth_hive_model.dart';
import 'package:path_provider/path_provider.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  // init
  Future<void> init() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${HiveTableConstant.dbName}';
    Hive.init(path);
    _registerAdapter();
    await openBoxes();
  }

  // Register Adapters
  void _registerAdapter() {
    if (!Hive.isAdapterRegistered(HiveTableConstant.authTypeId)) {
      Hive.registerAdapter(AuthHiveModelAdapter());
    }
  }

  // Open Boxes
  Future<void> openBoxes() async {
    await Hive.openBox<AuthHiveModel>(HiveTableConstant.authTable);
    await Hive.openBox<String>(HiveTableConstant.sessionTable);
    await Hive.openBox<bool>(HiveTableConstant.onboardingTable);
  }

  // Close Boxes
  Future<void> close() async {
    await Hive.close();
  }

  // auth Queries
  Box<AuthHiveModel> get _authBox =>
      Hive.box<AuthHiveModel>(HiveTableConstant.authTable);

  //Register
  Future<AuthHiveModel> registerUser(AuthHiveModel model) async {
    await _authBox.put(model.authId, model);
    return model;
  }

  // login
  Future<AuthHiveModel?> loginUser(String email, String password) async {
    final auths = _authBox.values.where(
      (auth) => auth.email == email && auth.password == password,
    );
    if (auths.isNotEmpty) {
      return auths.first;
    }
    return null;
  }

  //logout
  Future<void> logoutUser() async {}

  //get current user
  AuthHiveModel? getCurrentUser(String authId) {
    return _authBox.get(authId);
  }

  // isemail exist
  bool isEmailExist(String email) {
    final auths = _authBox.values.where((auth) => auth.email == email);
    return auths.isNotEmpty;
  }

  // Session management
  Box<String> get _sessionBox => Hive.box<String>(HiveTableConstant.sessionTable);

  Future<void> saveSession(String authId) async {
    await _sessionBox.put('currentAuthId', authId);
  }

  String? getCurrentSession() {
    return _sessionBox.get('currentAuthId');
  }

  Future<void> clearSession() async {
    await _sessionBox.delete('currentAuthId');
  }

  bool isLoggedIn() {
    return _sessionBox.get('currentAuthId') != null;
  }

  // Onboarding management
  Box<bool> get _onboardingBox => Hive.box<bool>(HiveTableConstant.onboardingTable);

  Future<void> completeOnboarding() async {
    await _onboardingBox.put('completed', true);
  }

  bool hasCompletedOnboarding() {
    return _onboardingBox.get('completed') ?? false;
  }

  Future<void> clearOnboarding() async {
    await _onboardingBox.delete('completed');
  }
}
