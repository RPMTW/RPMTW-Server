import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/db_model.dart';
import 'package:rpmtw_server/database/index_fields.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';

class WikiChangeLog extends DBModel {
  static const String collectionName = 'rpmwiki_wiki_change_log';
  static const List<IndexField> indexFields = [
    IndexField('userUUID', unique: false),
    IndexField('dataUUID', unique: false),
    IndexField('type', unique: false),
    IndexField('time', unique: false),
  ];

  /// 變更日誌
  final String? changelog;

  /// 修改類型
  final WikiChangeLogType type;

  /// 修改的資料 UUID (可能是 [MinecraftMod] )
  final String dataUUID;

  /// 修改的資料內容 (可能是 [MinecraftMod] )
  final Map<String, dynamic> changedData;

  final String userUUID;

  final DateTime time;

  const WikiChangeLog({
    this.changelog,
    required this.type,
    required this.dataUUID,
    required this.changedData,
    required this.userUUID,
    required this.time,
    required String uuid,
  }) : super(uuid: uuid);

  @override
  Map<String, dynamic> toMap() {
    return {
      'changelog': changelog,
      'type': type.name,
      'dataUUID': dataUUID,
      'changedData': json.encode(changedData),
      'userUUID': userUUID,
      'time': time.millisecondsSinceEpoch,
      'uuid': uuid,
    };
  }

  Future<Map<String, dynamic>> output() async {
    List<WikiChangeLog> changelogs = await DataBase.instance
        .getModelsWithSelector<WikiChangeLog>(
            where.eq('dataUUID', dataUUID).sortBy('time'));
    Map<String, dynamic>? unchangedData;

    if (changelogs.isEmpty) {
      unchangedData = null;
    } else {
      try {
        WikiChangeLog thisChangelog =
            changelogs.firstWhere((e) => e.uuid == uuid);
        unchangedData =
            changelogs[changelogs.indexOf(thisChangelog) - 1].changedData;
      } catch (e) {
        unchangedData = null;
      }
    }

    return {
      'changelog': changelog,
      'type': type.name,
      'dataUUID': dataUUID,
      'changedData': changedData,
      'unchangedData': unchangedData,
      'userUUID': userUUID,
      'time': time.millisecondsSinceEpoch,
      'uuid': uuid,
    };
  }

  factory WikiChangeLog.fromMap(Map<String, dynamic> map) {
    return WikiChangeLog(
      changelog: map['changelog'],
      type: WikiChangeLogType.values.byName(map['type']),
      dataUUID: map['dataUUID'],
      changedData:
          map['changedData'] != null ? json.decode(map['changedData']) : {},
      userUUID: map['userUUID'],
      time: DateTime.fromMillisecondsSinceEpoch(map['time'], isUtc: true),
      uuid: map['uuid'],
    );
  }
}

enum WikiChangeLogType {
  // 新增模組
  addedMod,
  // 編輯模組
  editedMod,
  // 刪除模組
  removedMod,
}
