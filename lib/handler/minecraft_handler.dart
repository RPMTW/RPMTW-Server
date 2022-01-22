import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/minecraft/relation_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_integration.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_side.dart';
import 'package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_change_log.dart';
import 'package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_mod_data.dart';

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
        loader: loader);

    await mod.insert();
    return mod;
  }

  static Future<List<MinecraftMod>> searchMods(
      {String? filter, int? limit, int? skip}) async {
    limit ??= 50;
    skip ??= 0;
    if (limit > 50) {
      /// 最多搜尋 50 筆資料
      limit = 50;
    }

    List<MinecraftMod> mods = [];

    Future<void> _searchByMinecraftMod() async {
      final DbCollection collection =
          DataBase.instance.getCollection<MinecraftMod>();

      SelectorBuilder builder = SelectorBuilder();
      if (filter != null) {
        /// search by name or id
        builder = builder.match('id', filter).or(where.match('name', filter));
      }
      builder = builder.limit(limit!).skip(skip!);

      final List<Map<String, dynamic>> modMaps =
          await collection.find(builder).toList();

      for (final Map<String, dynamic> map in modMaps) {
        mods.add(MinecraftMod.fromMap(map));
      }
    }

    Future<void> _searchByWikiModData() async {
      final DbCollection collection =
          DataBase.instance.getCollection<WikiModData>();

      SelectorBuilder builder = SelectorBuilder();
      if (filter != null) {
        /// search by translated name
        builder = builder.match('translatedName', filter);
      }
      builder = builder.limit(limit!).skip(skip!);

      final List<Map<String, dynamic>> modMaps =
          await collection.find(builder).toList();

      for (final Map<String, dynamic> map in modMaps) {
        WikiModData wikiData = WikiModData.fromMap(map);
        MinecraftMod? mod = await MinecraftMod.getByUUID(wikiData.modUUID);
        if (mod != null) {
          /// remove duplicate
          if (mods.any((e) => e.uuid == mod.uuid)) {
            continue;
          }

          mods.add(mod);
        }
      }
    }

    await _searchByMinecraftMod();
    await _searchByWikiModData();

    mods.sort((MinecraftMod a, MinecraftMod b) {
      return a.createTime.compareTo(b.createTime);
    });

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
