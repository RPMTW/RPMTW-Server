import "package:dart_jsonwebtoken/dart_jsonwebtoken.dart";
import "package:rpmtw_server/database/database.dart";
import "package:rpmtw_server/database/models/index_fields.dart";
import "package:rpmtw_server/handler/auth_handler.dart";

import "../base_models.dart";

class User extends BaseModel {
  static const String collectionName = "users";
  static const List<IndexField> indexFields = [
    IndexField("email", unique: true)
  ];

  final String username;
  final String email;
  final bool emailVerified;
  final String passwordHash;
  final String? avatarStorageUUID;
  final List<String> loginIPs;

  const User({
    required String uuid,
    required this.username,
    required this.email,
    required this.emailVerified,
    required this.passwordHash,
    this.avatarStorageUUID,
    required this.loginIPs,
  }) : super(uuid: uuid);

  User copyWith({
    String? username,
    String? email,
    bool? emailVerified,
    String? passwordHash,
    String? avatarStorageUUID,
    List<String>? loginIPs,
  }) {
    return User(
      uuid: uuid,
      username: username ?? this.username,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      passwordHash: passwordHash ?? this.passwordHash,
      avatarStorageUUID: avatarStorageUUID ?? this.avatarStorageUUID,
      loginIPs: loginIPs ?? this.loginIPs,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "uuid": uuid,
      "username": username,
      "email": email,
      "emailVerified": emailVerified,
      "passwordHash": passwordHash,
      "avatarStorageUUID": avatarStorageUUID,
      "loginIPs": loginIPs,
    };
  }

  @override
  Map<String, dynamic> outputMap() {
    return {
      "uuid": uuid,
      "username": username,
      "email": email,
      "emailVerified": emailVerified,
      "avatarStorageUUID": avatarStorageUUID,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uuid: map["uuid"],
      username: map["username"],
      email: map["email"],
      emailVerified: map["emailVerified"] ?? false,
      passwordHash: map["passwordHash"],
      avatarStorageUUID: map["avatarStorageUUID"],
      loginIPs: List<String>.from(map["loginIPs"] ?? []),
    );
  }

  static Future<User?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<User>(uuid);

  static Future<User?> getByEmail(String email) async =>
      DataBase.instance.getModelByField<User>("email", email);

  static Future<User?> getByToken(String token) async {
    JWT jwt = JWT.verify(token, AuthHandler.secretKey);
    Map<String, dynamic> payload = jwt.payload;
    String uuid = payload["uuid"];
    return await DataBase.instance.getModelByUUID<User>(uuid);
  }
}
