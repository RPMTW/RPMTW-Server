import 'dart:convert';

import '../base_models.dart';

class User extends BaseModels {
  final String username;
  final String email;
  final bool emailVerified;
  final String passwordHash;
  final String? avatarStorageUUID;

  const User({
    required String uuid,
    required this.username,
    required this.email,
    required this.emailVerified,
    required this.passwordHash,
    this.avatarStorageUUID,
  }) : super(uuid: uuid);

  User copyWith({
    String? uuid,
    String? username,
    String? email,
    bool? emailVerified,
    String? passwordHash,
    String? avatarStorageUUID,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      username: username ?? this.username,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      passwordHash: passwordHash ?? this.passwordHash,
      avatarStorageUUID: avatarStorageUUID ?? this.avatarStorageUUID,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'username': username,
      'email': email,
      'emailVerified': emailVerified,
      'passwordHash': passwordHash,
      'avatarStorageUUID': avatarStorageUUID,
    };
  }

  @override
  Map<String, dynamic> outputMap() {
    return {
      'uuid': uuid,
      'username': username,
      'email': email,
      'emailVerified': emailVerified,
      'avatarStorageUUID': avatarStorageUUID,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uuid: map['uuid'] ?? '',
      username: map['username'],
      email: map['email'],
      emailVerified: map['emailVerified'] ?? false,
      passwordHash: map['passwordHash'] ?? '',
      avatarStorageUUID: map['avatarStorageUUID'],
    );
  }

  @override
  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(uuid: $uuid, username: $username, email: $email,emailVerified: $emailVerified, passwordHash: $passwordHash, avatarStorageUUID: $avatarStorageUUID)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.uuid == uuid &&
        other.username == username &&
        other.email == email &&
        other.emailVerified == emailVerified &&
        other.passwordHash == passwordHash &&
        other.avatarStorageUUID == avatarStorageUUID;
  }

  @override
  int get hashCode {
    return uuid.hashCode ^
        username.hashCode ^
        email.hashCode ^
        emailVerified.hashCode ^
        passwordHash.hashCode ^
        avatarStorageUUID.hashCode;
  }
}
