import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/database/models/minecraft/relation_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_integration.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_side.dart';

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

  static Future<List<MinecraftMod>> search(
      {String? filter, int? limit, int? skip}) async {
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
      builder = builder.match('id', filter).or(where.match('name', filter));
    }
    builder = builder.limit(limit).skip(skip);

    final List<Map<String, dynamic>> modMaps =
        await collection.find(builder).toList();

    for (final Map<String, dynamic> map in modMaps) {
      mods.add(MinecraftMod.fromMap(map));
    }

    return mods;
  }
}
