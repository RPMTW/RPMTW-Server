import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/minecraft/relation_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_integration.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_side.dart';
import 'package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_change_log.dart';

class MinecraftHeader {
  static Future<MinecraftMod> createMod({
    required String name,
    required List<MinecraftVersion> supportVersions,
    String? id,
    String? description,
    List<RelationMod>? relationMods,
    ModIntegrationPlatform? integration,
    List<ModSide>? side,
    List<ModLoader>? loader,
    String? translatedName,
    String? introduction,
    String? imageStorageUUID,
    int viewCount = 0,
  }) async {
    DateTime nowTime = DateTime.now().toUtc();

    MinecraftMod mod = MinecraftMod(
      uuid: Uuid().v4(),
      name: name,
      id: id,
      description: description,
      supportVersions: supportVersions,
      relationMods: relationMods ?? [],
      integration: integration ?? ModIntegrationPlatform(),
      side: side ?? [],
      lastUpdate: nowTime,
      createTime: nowTime,
      loader: loader,
      translatedName: translatedName,
      introduction: introduction,
      imageStorageUUID: imageStorageUUID,
      viewCount: viewCount,
    );

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
          .or(where.match('name', filter))
          .or(where.match('translatedName', filter));
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
