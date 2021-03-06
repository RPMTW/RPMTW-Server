import 'package:rpmtw_server/database/database.dart';

import 'package:rpmtw_server/database/db_model.dart';
import 'package:rpmtw_server/database/index_fields.dart';

class BanInfo extends DBModel {
  static const String collectionName = 'ban_infos';
  static const List<IndexField> indexFields = [
    IndexField('ip', unique: true),
  ];

  /// 被封鎖的 IP
  final String ip;

  /// 封鎖原因
  final String reason;

  /// 使用此 IP 登入的使用者帳號 UUID
  final List<String> userUUID;

  const BanInfo({
    required this.ip,
    required this.reason,
    required this.userUUID,
    required String uuid,
  }) : super(uuid: uuid);

  BanInfo copyWith({
    String? ip,
    String? reason,
    List<String>? userUUID,
  }) {
    return BanInfo(
      ip: ip ?? this.ip,
      reason: reason ?? this.reason,
      userUUID: userUUID ?? this.userUUID,
      uuid: uuid,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'ip': ip,
      'reason': reason,
      'userUUID': userUUID,
      'uuid': uuid,
    };
  }

  factory BanInfo.fromMap(Map<String, dynamic> map) {
    return BanInfo(
      ip: map['ip'],
      reason: map['reason'],
      userUUID: List<String>.from(map['userUUID']),
      uuid: map['uuid']!,
    );
  }

  static Future<BanInfo?> getByIP(String ip) async =>
      DataBase.instance.getModelByField<BanInfo>('ip', ip);
}
