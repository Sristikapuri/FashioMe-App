import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';
import 'package:fashio_me/features/auth/presentation/providers/auth_session_providers.dart';
import 'package:fashio_me/features/auth/presentation/state/login_state.dart';
import 'package:fashio_me/features/auth/presentation/state/signup_state.dart';
import 'package:fashio_me/features/auth/presentation/view_model/login_view_model.dart';
import 'package:fashio_me/features/auth/presentation/view_model/signup_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'auth_session_providers.dart';

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  LoginViewModel.new,
);

final signupViewModelProvider = NotifierProvider<SignupViewModel, SignupState>(
  SignupViewModel.new,
);

/// Read-only access to the signed-in user from session state.
final currentUserProvider = Provider<AuthEntity?>((ref) {
  return ref.watch(authSessionViewModelProvider).user;
});
