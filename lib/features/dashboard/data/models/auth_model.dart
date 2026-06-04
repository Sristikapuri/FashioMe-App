import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';

class AuthModel {
  final String? authId;
  final String fullName;
  final String email;
  final String? password;

  AuthModel({
    this.authId,
    required this.fullName,
    required this.email,
    this.password,
  });

  factory AuthModel.fromEntity(AuthEntity entity) {
    return AuthModel(
      authId: entity.authId,
      fullName: entity.fullName,
      email: entity.email,
      password: entity.password,
    );
  }

  AuthEntity toEntity() {
    return AuthEntity(
      authId: authId,
      fullName: fullName,
      email: email,
      password: password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authId': authId,
      'fullName': fullName,
      'email': email,
      'password': password,
    };
  }

  AuthModel copyWith({
    String? authId,
    String? fullName,
    String? email,
    String? password,
  }) {
    return AuthModel(
      authId: authId ?? this.authId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      authId: json['authId'],
      fullName: json['fullName'],
      email: json['email'],
      password: json['password'],
    );
  }
}
