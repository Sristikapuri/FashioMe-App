import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String? authId;
  final String fullName;
  final String email;
  final String? password;
  final String? gender;
  final String? age;

  const AuthEntity({
    this.authId,
    required this.fullName,
    required this.email,
    this.password,
    this.gender,
    this.age,
  });

  @override
  List<Object?> get props => [authId, fullName, email, password, gender, age];
}
