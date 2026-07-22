import 'package:fashio_me/features/auth/domain/entities/auth_entity.dart';

class AuthModel {
  final String? authId;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? gender;
  final String? age;
  final String? role;
  final String? password;

  AuthModel({
    this.authId,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.gender,
    this.age,
    this.role,
    this.password,
  });

  String get fullName {
    final parts = [
      firstName.trim(),
      lastName.trim(),
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(' ');
  }

  static String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  static String? _nullableStringValue(dynamic value) {
    final normalized = _stringValue(value);
    return normalized.isEmpty ? null : normalized;
  }

  static ({String firstName, String lastName}) _splitFullName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return (firstName: '', lastName: '');
    }

    final parts = normalized.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return (firstName: parts.first, lastName: '');
    }

    return (firstName: parts.first, lastName: parts.sublist(1).join(' '));
  }

  factory AuthModel.fromEntity(AuthEntity entity) {
    return AuthModel(
      authId: entity.authId,
      firstName: entity.firstName,
      lastName: entity.lastName,
      username: entity.username,
      email: entity.email,
      gender: entity.gender,
      age: entity.age,
      role: entity.role,
      password: entity.password,
    );
  }

  AuthEntity toEntity() {
    return AuthEntity(
      authId: authId,
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      gender: gender,
      age: age,
      role: role,
      password: password,
    );
  }

  Map<String, dynamic> toJson() {
    final normalizedGender = gender?.trim().toLowerCase();
    final parsedAge = int.tryParse(age?.trim() ?? '');

    final payload = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
    };

    if (authId != null) {
      payload['authId'] = authId;
    }
    if (normalizedGender != null && normalizedGender.isNotEmpty) {
      payload['gender'] = normalizedGender;
    }
    if (parsedAge != null) {
      payload['age'] = parsedAge;
    }
    if (role != null) {
      payload['role'] = role;
    }
    if (password != null) {
      payload['password'] = password;
    }

    return payload;
  }

  AuthModel copyWith({
    String? authId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? gender,
    String? age,
    String? role,
    String? password,
  }) {
    return AuthModel(
      authId: authId ?? this.authId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      role: role ?? this.role,
      password: password ?? this.password,
    );
  }

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final fallbackName = _splitFullName(_stringValue(json['fullName']));
    final email = _stringValue(json['email']);

    // Handle nested responseData structure
    Map<String, dynamic> userData = json;
    if (json['responseData'] is Map<String, dynamic>) {
      userData = json['responseData'] as Map<String, dynamic>;
    }

    return AuthModel(
      authId: _nullableStringValue(
        userData['authId'] ??
            userData['_id'] ??
            userData['id'] ??
            json['authId'] ??
            json['_id'] ??
            json['id'],
      ),
      firstName:
          _nullableStringValue(userData['firstName'] ?? json['firstName']) ??
          fallbackName.firstName,
      lastName:
          _nullableStringValue(userData['lastName'] ?? json['lastName']) ??
          fallbackName.lastName,
      username:
          _nullableStringValue(
            userData['username'] ??
                userData['userName'] ??
                json['username'] ??
                json['userName'],
          ) ??
          (email.contains('@') ? email.split('@').first : ''),
      email: _stringValue(userData['email'] ?? json['email']),
      gender: _nullableStringValue(userData['gender'] ?? json['gender']),
      age: _nullableStringValue(userData['age'] ?? json['age']),
      role: _nullableStringValue(userData['role'] ?? json['role']),
      password: _nullableStringValue(userData['password'] ?? json['password']),
    );
  }
}
