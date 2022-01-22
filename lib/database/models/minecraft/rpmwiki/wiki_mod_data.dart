import 'dart:convert';

import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/base_models.dart';
import 'package:rpmtw_server/database/models/index_fields.dart';

class WikiModData extends BaseModels {
  static const String collectionName = "rpmwiki_wiki_mod_data";
  static const List<IndexFields> indexFields = [
    IndexFields("modUUID", unique: true),
    IndexFields("translatedName", unique: false),
  ];

  /// 該模組的 UUID
  final String modUUID;

  /// 已翻譯過的模組名稱
  final String? translatedName;

  /// 模組的介紹文章 (Markdown 格式)
  final String? introduction;

  /// 模組的封面圖 (Storage UUID)
  final String? imageStorageUUID;

  /// 模組瀏覽次數
  final int viewCount;

  const WikiModData({
    required String uuid,
    required this.modUUID,
    this.translatedName,
    this.introduction,
    this.imageStorageUUID,
    this.viewCount = 0,
  }) : super(uuid: uuid);

  WikiModData copyWith({
    String? uuid,
    String? modUUID,
    String? translatedName,
    String? introduction,
    String? imageStorageUUID,
    int? viewCount,
  }) {
    return WikiModData(
      uuid: uuid ?? this.uuid,
      modUUID: modUUID ?? this.modUUID,
      translatedName: translatedName ?? this.translatedName,
      introduction: introduction ?? this.introduction,
      imageStorageUUID: imageStorageUUID ?? this.imageStorageUUID,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'modUUID': modUUID,
      'translatedName': translatedName,
      'introduction': introduction,
      'imageStorageUUID': imageStorageUUID,
      'viewCount': viewCount,
    };
  }

  factory WikiModData.fromMap(Map<String, dynamic> map) {
    return WikiModData(
      uuid: map['uuid'] ?? '',
      modUUID: map['modUUID'] ?? '',
      translatedName: map['translatedName'],
      introduction: map['introduction'],
      imageStorageUUID: map['imageStorageUUID'],
      viewCount: map['viewCount'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory WikiModData.fromJson(String source) =>
      WikiModData.fromMap(json.decode(source));

  @override
  String toString() {
    return 'WikiModData(uuid: $uuid, modUUID: $modUUID, translatedName: $translatedName, introduction: $introduction, imageStorageUUID: $imageStorageUUID, viewCount: $viewCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WikiModData &&
        other.uuid == uuid &&
        other.modUUID == modUUID &&
        other.translatedName == translatedName &&
        other.introduction == introduction &&
        other.imageStorageUUID == imageStorageUUID &&
        other.viewCount == viewCount;
  }

  @override
  int get hashCode {
    return uuid.hashCode ^
        modUUID.hashCode ^
        translatedName.hashCode ^
        introduction.hashCode ^
        imageStorageUUID.hashCode ^
        viewCount.hashCode;
  }

  static Future<WikiModData?> getByUUID(String uuid) async =>
      DataBase.instance.getModelByUUID<WikiModData>(uuid);

  static Future<WikiModData?> getByModUUID(String modUUID) async =>
      DataBase.instance.getModelByField<WikiModData>('modUUID', modUUID);

  static Future<WikiModData?> getByTranslatedName(
          String translatedName) async =>
      DataBase.instance
          .getModelByField<WikiModData>("translatedName", translatedName);
}
