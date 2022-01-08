import 'dart:convert';
import 'dart:math';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/base_models.dart';

class AuthCode extends BaseModels {
  final int code;
  final DateTime expiresAt;
  final String email;
  AuthCode({
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
        expiresAt: DateTime.now().add(Duration(minutes: 30)), // 驗證碼有效時間為 30 分鐘
        email: email);
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  AuthCode copyWith({
    int? code,
    DateTime? expiresAt,
    String? uuid,
    String? email,
  }) {
    return AuthCode(
      code: code ?? this.code,
      expiresAt: expiresAt ?? this.expiresAt,
      uuid: uuid ?? this.uuid,
      email: email ?? this.email,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'uuid': uuid,
      'email': email,
    };
  }

  factory AuthCode.fromMap(Map<String, dynamic> map) {
    return AuthCode(
      code: map['code']?.toInt() ?? 0,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt']),
      uuid: map['uuid'],
      email: map['email'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AuthCode.fromJson(String source) =>
      AuthCode.fromMap(json.decode(source));

  @override
  String toString() =>
      'AuthCode(code: $code, expiresAt: $expiresAt, uuid: $uuid, email: $email)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthCode &&
        other.code == code &&
        other.expiresAt == expiresAt &&
        other.uuid == uuid &&
        other.email == email;
  }

  @override
  int get hashCode =>
      code.hashCode ^ expiresAt.hashCode ^ uuid.hashCode ^ email.hashCode;

  static Future<AuthCode?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<AuthCode>(uuid);

  static Future<AuthCode?> getByCode(int code) async =>
      DataBase.instance.getModelByField<AuthCode>("code", code);
}
