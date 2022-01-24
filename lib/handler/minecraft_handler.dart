import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version_manifest.dart';
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

    List<MinecraftVersion> allVersions =
        (await MinecraftVersionManifest.getFromCache()).manifest.versions;
    List<MinecraftVersion>? supportedVersions;
    try {
      supportedVersions = List<MinecraftVersion>.from(body['supportVersions']
          ?.map((x) => allVersions.firstWhere((e) => e.id == x)));
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
    DateTime nowTime = DateTime.now().toUtc();

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

    List<MinecraftMod> mods = [];

    final DbCollection collection =
        DataBase.instance.getCollection<MinecraftMod>();

    SelectorBuilder builder = SelectorBuilder();
    if (filter != null) {
      /// search by name or id
      builder = builder
          .match('id', filter)
          .or(where.match('name', "(?i)$filter"))
          .or(where.match('translatedName', "(?i)$filter"));
    }
    builder = builder.limit(limit).skip(skip);

    if (sort == 0) {
      builder = builder.sortBy('createTime');
    } else if (sort == 1) {
      builder = builder.sortBy('viewCount');
    } else if (sort == 2) {
      builder = builder.sortBy('name');
    } else if (sort == 3) {
      builder = builder.sortBy('lastUpdate');
    }

    final List<Map<String, dynamic>> modMaps =
        await collection.find(builder).toList();

    for (final Map<String, dynamic> map in modMaps) {
      MinecraftMod mod = MinecraftMod.fromMap(map);
      mods.add(mod);
    }

    return mods;
  }

  static Future<List<WikiChangeLog>> filterChangelogs(
      {int? limit, int? skip}) async {
    limit ??= 50;
    skip ??= 0;
    if (limit > 50) {
      /// 最多搜尋 50 筆資料
      limit = 50;
    }

    List<WikiChangeLog> changelogs = [];

    final DbCollection collection =
        DataBase.instance.getCollection<WikiChangeLog>();

    final List<Map<String, dynamic>> changelogMaps =
        await collection.find(where.limit(limit).skip(skip)).toList();

    for (final Map<String, dynamic> map in changelogMaps) {
      changelogs.add(WikiChangeLog.fromMap(map));
    }

    return changelogs;
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
