import 'package:rpmtw_server/database/database.dart';

import 'package:rpmtw_server/database/db_model.dart';
import 'package:rpmtw_server/database/index_fields.dart';
import 'package:rpmtw_server/database/model_field.dart';
import 'package:rpmtw_server/database/models/auth/ban_category.dart';

class BanInfo extends DBModel {
  static const String collectionName = 'ban_infos';
  static const List<IndexField> indexFields = [
    IndexField('ip', unique: true),
  ];

  /// 被封鎖的 IP
  final String ip;

  /// 封鎖原因
  final String reason;

  final BanCategory category;

  /// 使用此 IP 登入的使用者帳號 UUID
  final List<String> userUUID;

  const BanInfo({
    required this.ip,
    required this.reason,
    required this.category,
    required this.userUUID,
    required String uuid,
  }) : super(uuid: uuid);

  BanInfo copyWith({
    String? ip,
    String? reason,
    BanCategory? category,
    List<String>? userUUID,
  }) {
    return BanInfo(
      ip: ip ?? this.ip,
      reason: reason ?? this.reason,
      category: category ?? this.category,
      userUUID: userUUID ?? this.userUUID,
      uuid: uuid,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'ip': ip,
      'reason': reason,
      'category': category.name,
      'userUUID': userUUID,
      'uuid': uuid,
    };
  }

  factory BanInfo.fromMap(Map<String, dynamic> map) {
    return BanInfo(
      ip: map['ip'],
      reason: map['reason'],
      category: BanCategory.values.byName(map['category']),
      userUUID: List<String>.from(map['userUUID']),
      uuid: map['uuid']!,
    );
  }

  static Future<List<BanInfo>> getByIP(String ip) async =>
      DataBase.instance.getModelsByField<BanInfo>([ModelField('ip', ip)]);
}
