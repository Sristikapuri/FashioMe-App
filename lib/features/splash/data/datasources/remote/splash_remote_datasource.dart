import 'package:fashio_me/features/splash/data/datasources/splash_datasource.dart';

class SplashRemoteDataSource implements ISplashDataSource {
  @override
  bool isLoggedIn() {
    // In a real app, this would check with an API
    return false;
  }

  @override
  bool hasCompletedOnboarding() {
    // In a real app, this would check with an API
    return false;
  }
}
