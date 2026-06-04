import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String? authId;
  final String fullName;
  final String email;
  final String? password;

  const AuthEntity({
    this.authId,
    required this.fullName,
    required this.email,
    this.password,
  });

  @override
  List<Object?> get props => [authId, fullName, email, password];
}
