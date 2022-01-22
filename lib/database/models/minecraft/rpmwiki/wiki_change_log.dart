import 'dart:convert';

import 'package:rpmtw_server/database/models/base_models.dart';
import 'package:rpmtw_server/database/models/index_fields.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_mod_data.dart';

class WikiChangeLog extends BaseModels {
  static const String collectionName = "rpmwiki_wiki_change_log";
  static const List<IndexFields> indexFields = [
    IndexFields("userUUID", unique: false),
    IndexFields("type", unique: false),
  ];

  /// 變更日誌
  final String? changeLog;

  /// 修改類型
  final WikiChangeLogType type;

  /// 修改的資料 (可能是 [MinecraftMod] 或 [WikiModData] 的 UUID )
  final String dataUUID;

  final String userUUID;

  final DateTime time;
  WikiChangeLog({
    this.changeLog,
    required this.type,
    required this.dataUUID,
    required this.userUUID,
    required this.time,
    required String uuid,
  }) : super(uuid: uuid);

  WikiChangeLog copyWith({
    String? changeLog,
    WikiChangeLogType? type,
    String? dataUUID,
    String? userUUID,
    DateTime? time,
    String? uuid,
  }) {
    return WikiChangeLog(
      changeLog: changeLog ?? this.changeLog,
      type: type ?? this.type,
      dataUUID: dataUUID ?? this.dataUUID,
      userUUID: userUUID ?? this.userUUID,
      time: time ?? this.time,
      uuid: uuid ?? this.uuid,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'changeLog': changeLog,
      'type': type.name,
      'dataUUID': dataUUID,
      'userUUID': userUUID,
      'time': time.millisecondsSinceEpoch,
      'uuid': uuid,
    };
  }

  factory WikiChangeLog.fromMap(Map<String, dynamic> map) {
    return WikiChangeLog(
      changeLog: map['changeLog'],
      type: WikiChangeLogType.values.byName(map['type']),
      dataUUID: map['dataUUID'] ?? '',
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
    return 'WikiChangeLog(changeLog: $changeLog, type: $type, dataUUID: $dataUUID, userUUID: $userUUID, time: $time, uuid: $uuid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WikiChangeLog &&
        other.changeLog == changeLog &&
        other.type == type &&
        other.dataUUID == dataUUID &&
        other.userUUID == userUUID &&
        other.time == time &&
        other.uuid == uuid;
  }

  @override
  int get hashCode {
    return changeLog.hashCode ^
        type.hashCode ^
        dataUUID.hashCode ^
        userUUID.hashCode ^
        time.hashCode ^
        uuid.hashCode;
  }
}

enum WikiChangeLogType {
  // 新增模組
  addedMod,
  // 編輯模組
  modifiedMod,
  // 刪除模組
  removedMod,
  // 新增模組維基資料
  addedWikiModData,
  // 編輯模組維基資料
  modifiedWikiModData,
  // 刪除模組維基資料
  removedWikiModData,
}
