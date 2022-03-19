import "dart:math";

import "package:mongo_dart/mongo_dart.dart";
import "package:rpmtw_server/database/database.dart";
import "package:rpmtw_server/database/models/base_models.dart";
import "package:rpmtw_server/database/models/index_fields.dart";

class AuthCode extends BaseModel {
  static const String collectionName = "auth_codes";
  static const List<IndexField> indexFields = [
    IndexField("code", unique: true),
    IndexField("expiresAt", unique: false)
  ];

  final int code;
  final DateTime expiresAt;
  final String email;

  const AuthCode({
    required String uuid,
    required this.code,
    required this.expiresAt,
    required this.email,
  }) : super(uuid: uuid);

  factory AuthCode.create(String email) {
    int code = Random.secure().nextInt(999999);
    return AuthCode(
        uuid: Uuid().v4(),
        code: code,
        expiresAt:
            DateTime.now().toUtc().add(Duration(minutes: 30)), // 驗證碼有效時間為 30 分鐘
        email: email);
  }

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  AuthCode copyWith({
    int? code,
    DateTime? expiresAt,
    String? email,
  }) {
    return AuthCode(
      code: code ?? this.code,
      expiresAt: expiresAt ?? this.expiresAt,
      uuid: uuid,
      email: email ?? this.email,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "code": code,
      "expiresAt": expiresAt.millisecondsSinceEpoch,
      "uuid": uuid,
      "email": email,
    };
  }

  factory AuthCode.fromMap(Map<String, dynamic> map) {
    return AuthCode(
      code: map["code"]?.toInt() ?? 0,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map["expiresAt"]),
      uuid: map["uuid"],
      email: map["email"],
    );
  }

  static Future<AuthCode?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<AuthCode>(uuid);

  static Future<AuthCode?> getByCode(int code) async =>
      DataBase.instance.getModelByField<AuthCode>("code", code);
}
