import 'package:fashio_me/features/auth/presentation/state/auth_session_state.dart';
import 'package:fashio_me/features/auth/presentation/view_model/auth_session_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authSessionViewModelProvider =
    NotifierProvider<AuthSessionViewModel, AuthSessionState>(
      AuthSessionViewModel.new,
    );
