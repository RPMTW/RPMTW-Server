import 'package:mongo_dart/mongo_dart.dart';
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
}
