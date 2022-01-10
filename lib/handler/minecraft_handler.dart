import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/minecraft/relation_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_integration.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_side.dart';

class MinecraftHeader {
  static Future<MinecraftMod> createMod(
      {required String name,
      required String id,
      required List<MinecraftVersion> supportVersions,
      String? description,
      List<RelationMod>? relationMods,
      ModIntegration? integration,
      List<ModSide>? side}) async {
    DateTime nowTime = DateTime.now().toUtc();

    MinecraftMod mod = MinecraftMod(
        uuid: Uuid().v4(),
        name: name,
        id: id,
        description: description,
        supportVersions: supportVersions,
        relationMods: relationMods ?? [],
        integration: integration ?? ModIntegration(),
        side: side ?? [],
        lastUpdate: nowTime,
        createTime: nowTime);

    await mod.insert();
    return mod;
  }
}
