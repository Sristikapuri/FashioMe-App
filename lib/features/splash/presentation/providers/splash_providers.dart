import 'package:fashio_me/features/splash/presentation/state/splash_state.dart';
import 'package:fashio_me/features/splash/presentation/view_model/splash_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final splashViewModelProvider = NotifierProvider<SplashViewModel, SplashState>(
  SplashViewModel.new,
);
