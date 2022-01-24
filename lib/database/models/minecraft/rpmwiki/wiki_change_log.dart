import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/base_models.dart';
import 'package:rpmtw_server/database/models/index_fields.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';

class WikiChangeLog extends BaseModels {
  static const String collectionName = "rpmwiki_wiki_change_log";
  static const List<IndexFields> indexFields = [
    IndexFields("userUUID", unique: false),
    IndexFields("type", unique: false),
    IndexFields("time", unique: false),
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

  WikiChangeLog({
    this.changelog,
    required this.type,
    required this.dataUUID,
    required this.changedData,
    required this.userUUID,
    required this.time,
    required String uuid,
  }) : super(uuid: uuid);

  WikiChangeLog copyWith({
    String? changelog,
    WikiChangeLogType? type,
    String? dataUUID,
    Map<String, dynamic>? changedData,
    String? userUUID,
    DateTime? time,
    String? uuid,
  }) {
    return WikiChangeLog(
      changelog: changelog ?? this.changelog,
      type: type ?? this.type,
      dataUUID: dataUUID ?? this.dataUUID,
      changedData: changedData ?? this.changedData,
      userUUID: userUUID ?? this.userUUID,
      time: time ?? this.time,
      uuid: uuid ?? this.uuid,
    );
  }

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
    DbCollection collection = DataBase.instance.getCollection<WikiChangeLog>();
    List<WikiChangeLog> changelogs = await collection
        .find(where.eq("dataUUID", dataUUID).sortBy("time"))
        .map((e) => WikiChangeLog.fromMap(e))
        .toList();
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
      dataUUID: map['dataUUID'] ?? '',
      changedData:
          map['changedData'] != null ? json.decode(map['changedData']) : {},
      userUUID: map['userUUID'] ?? '',
      time: DateTime.fromMillisecondsSinceEpoch(map['time']),
      uuid: map['uuid'],
    );
  }

  String toJson() => json.encode(toMap());

  factory WikiChangeLog.fromJson(String source) =>
      WikiChangeLog.fromMap(json.decode(source));

  @override
  String toString() {
    return 'WikiChangeLog(changelog: $changelog, type: $type, dataUUID: $dataUUID, changedData: $changedData, userUUID: $userUUID, time: $time, uuid: $uuid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WikiChangeLog &&
        other.changelog == changelog &&
        other.type == type &&
        other.dataUUID == dataUUID &&
        other.changedData == changedData &&
        other.userUUID == userUUID &&
        other.time == time &&
        other.uuid == uuid;
  }

  @override
  int get hashCode {
    return changelog.hashCode ^
        type.hashCode ^
        dataUUID.hashCode ^
        changedData.hashCode ^
        userUUID.hashCode ^
        time.hashCode ^
        uuid.hashCode;
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
