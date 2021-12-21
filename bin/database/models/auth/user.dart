import 'dart:convert';

class User {
  final String uuid;
  final String username;
  final String email;
  final String passwordHash;
  final String salt;
  final String avatarStorageUUID;
  
  User({
    required this.uuid,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.salt,
    required this.avatarStorageUUID,
  });

  User copyWith({
    String? uuid,
    String? username,
    String? email,
    String? passwordHash,
    String? salt,
    String? avatarStorageUUID,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      avatarStorageUUID: avatarStorageUUID ?? this.avatarStorageUUID,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'username': username,
      'email': email,
      'passwordHash': passwordHash,
      'salt': salt,
      'avatarStorageUUID': avatarStorageUUID,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uuid: map['uuid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      passwordHash: map['passwordHash'] ?? '',
      salt: map['salt'] ?? '',
      avatarStorageUUID: map['avatarStorageUUID'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(uuid: $uuid, username: $username, email: $email, passwordHash: $passwordHash, salt: $salt, avatarStorageUUID: $avatarStorageUUID)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.uuid == uuid &&
        other.username == username &&
        other.email == email &&
        other.passwordHash == passwordHash &&
        other.salt == salt &&
        other.avatarStorageUUID == avatarStorageUUID;
  }

  @override
  int get hashCode {
    return uuid.hashCode ^
        username.hashCode ^
        email.hashCode ^
        passwordHash.hashCode ^
        salt.hashCode ^
        avatarStorageUUID.hashCode;
  }
}
