import 'package:equatable/equatable.dart';

class AuthEntity extends Equatable {
  final String? authId;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? password;
  final String? gender;
  final String? age;

  const AuthEntity({
    this.authId,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.password,
    this.gender,
    this.age,
  });

  String get fullName {
    final parts = [firstName.trim(), lastName.trim()]
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(' ');
  }

  @override
  List<Object?> get props => [authId, firstName, lastName, username, email, password, gender, age];
}
