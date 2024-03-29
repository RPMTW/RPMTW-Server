import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_dart_common_library/rpmtw_dart_common_library.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/minecraft/relation_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_integration.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_side.dart';
import 'package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_change_log.dart';

class MinecraftHeader {
  static Future<ModRequestBodyParsedResult> parseModRequestBody(
      Map<String, dynamic> body) async {
    String? name = body['name'];

    List<MinecraftVersion>? supportedVersions;
    try {
      supportedVersions = await MinecraftVersion.getByIDs(
          body['supportVersions']!.cast<String>());
    } catch (e) {
      supportedVersions = null;
    }

    String? id = body['id'];
    String? description = body['description'];
    List<RelationMod>? relationMods = body['relationMods'] != null
        ? List<RelationMod>.from(
            body['relationMods']!.map((x) => RelationMod.fromMap(x)))
        : null;
    ModIntegrationPlatform? integration = body['integration'] != null
        ? ModIntegrationPlatform.fromMap(body['integration'])
        : null;
    List<ModSide>? side = body['side'] != null
        ? List<ModSide>.from(
            body['side']!.map((x) => ModSide.fromMap(x)).toList())
        : null;
    List<ModLoader>? loader = body['loader'] != null
        ? List<ModLoader>.from(
            body['loader']?.map((x) => ModLoader.values.byName(x)))
        : null;
    String? translatedName = body['translatedName'];
    String? introduction = body['introduction'];
    String? imageStorageUUID = body['imageStorageUUID'];

    return ModRequestBodyParsedResult(
        name: name,
        supportVersions: supportedVersions,
        id: id,
        description: description,
        relationMods: relationMods,
        integration: integration,
        side: side,
        loader: loader,
        translatedName: translatedName,
        introduction: introduction,
        imageStorageUUID: imageStorageUUID);
  }

  static Future<MinecraftMod> createMod(
      ModRequestBodyParsedResult result) async {
    DateTime nowTime = RPMTWUtil.getUTCTime();

    MinecraftMod mod = MinecraftMod(
        uuid: Uuid().v4(),
        name: result.name!,
        id: result.id,
        description: result.description,
        supportVersions: result.supportVersions!,
        relationMods: result.relationMods ?? [],
        integration: result.integration ?? ModIntegrationPlatform(),
        side: result.side ?? [],
        lastUpdate: nowTime,
        createTime: nowTime,
        loader: result.loader,
        translatedName: result.translatedName,
        introduction: result.introduction,
        imageStorageUUID: result.imageStorageUUID,
        viewCount: 0);

    await mod.insert();
    return mod;
  }

  /// **[sort]** 排序方式
  /// 0 按照時間排序
  /// 1 按照瀏覽次數排序
  /// 2 按照模組名稱排序
  /// 3 按照最後修改日期排序
  static Future<List<MinecraftMod>> searchMods(
      {String? filter, int? limit, int? skip, int sort = 0}) async {
    limit ??= 50;
    skip ??= 0;
    if (limit > 50) {
      /// 最多搜尋 50 筆資料
      limit = 50;
    }

    SelectorBuilder selector = SelectorBuilder();
    if (filter != null) {
      /// search by name or id
      selector = selector
          .match('id', filter)
          .or(where.match('name', '(?i)$filter'))
          .or(where.match('translatedName', '(?i)$filter'));
    }
    selector.limit(limit).skip(skip);

    if (sort == 0) {
      selector.sortBy('createTime', descending: true);
    } else if (sort == 1) {
      selector.sortBy('viewCount', descending: true);
    } else if (sort == 2) {
      selector.sortBy('name', descending: true);
    } else if (sort == 3) {
      selector.sortBy('lastUpdate', descending: true);
    }

    return DataBase.instance.getModelsWithSelector<MinecraftMod>(selector);
  }

  static Future<List<WikiChangeLog>> filterChangelogs(
      {int? limit, int? skip, String? dataUUID, String? userUUID}) async {
    limit ??= 50;
    skip ??= 0;
    if (limit > 50) {
      /// 最多搜尋 50 筆資料
      limit = 50;
    }

    SelectorBuilder selector = SelectorBuilder();

    if (dataUUID != null && dataUUID.isNotEmpty) {
      selector.eq('dataUUID', dataUUID);
    }
    if (userUUID != null && userUUID.isNotEmpty) {
      selector.eq('userUUID', userUUID);
    }

    selector.limit(limit).skip(skip);

    return await DataBase.instance
        .getModelsWithSelector<WikiChangeLog>(selector);
  }
}

class ModRequestBodyParsedResult {
  final String? name;
  final List<MinecraftVersion>? supportVersions;
  final String? id;
  final String? description;
  final List<RelationMod>? relationMods;
  final ModIntegrationPlatform? integration;
  final List<ModSide>? side;
  final List<ModLoader>? loader;
  final String? translatedName;
  final String? introduction;
  final String? imageStorageUUID;

  ModRequestBodyParsedResult({
    this.name,
    this.supportVersions,
    this.id,
    this.description,
    this.relationMods,
    this.integration,
    this.side,
    this.loader,
    this.translatedName,
    this.introduction,
    this.imageStorageUUID,
  });
}
