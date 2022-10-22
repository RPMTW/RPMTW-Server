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

  /// The IP address of the banned user
  final String? ip;

  final String reason;

  final BanCategory category;

  final List<String> userUUID;

  final DateTime createdAt;

  final String? operatorUUID;

  const BanInfo({
    this.ip,
    required this.reason,
    required this.category,
    required this.userUUID,
    required this.createdAt,
    this.operatorUUID,
    required String uuid,
  }) : super(uuid: uuid);

  @override
  Map<String, dynamic> toMap() {
    return {
      'ip': ip,
      'reason': reason,
      'category': category.name,
      'userUUID': userUUID,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'operatorUUID': operatorUUID,
      'uuid': uuid,
    };
  }

  @override
  Map<String, dynamic> outputMap() {
    return {
      'reason': reason,
      'category': category.name,
      'userUUID': userUUID,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'operatorUUID': operatorUUID,
      'uuid': uuid,
    };
  }

  factory BanInfo.fromMap(Map<String, dynamic> map) {
    return BanInfo(
      ip: map['ip'],
      reason: map['reason'],
      category: BanCategory.values.byName(map['category']),
      userUUID: List<String>.from(map['userUUID']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      operatorUUID: map['operatorUUID'],
      uuid: map['uuid']!,
    );
  }

  static Future<BanInfo?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<BanInfo>(uuid);

  static Future<List<BanInfo>> getByUserUUID(String userUUID) async =>
      DataBase.instance
          .getModelsByField<BanInfo>([ModelField('userUUID', userUUID)]);

  static Future<List<BanInfo>> getByIP(String ip) async =>
      DataBase.instance.getModelsByField<BanInfo>([ModelField('ip', ip)]);

  static Future<BanInfo?> isBanned(BanCategory category,
      {String? ip, String? userUUID}) async {
    List<BanInfo> bans = [];
    if (ip != null) {
      bans.addAll(await getByIP(ip));
    }
    if (userUUID != null) {
      bans.addAll(await getByUserUUID(userUUID));
    }

    try {
      return bans.firstWhere((ban) =>
          ban.category == category || ban.category == BanCategory.permanent);
    } catch (e) {
      return null;
    }
  }
}
