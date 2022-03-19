import "package:mongo_dart/mongo_dart.dart";
import 'package:rpmtw_server/database/models/auth_route.dart';
import "package:rpmtw_server/database/models/minecraft/minecraft_version_manifest.dart";
import "package:rpmtw_server/database/models/minecraft/minecraft_mod.dart";
import "package:rpmtw_server/database/models/minecraft/minecraft_version.dart";
import "package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_change_log.dart";
import "package:rpmtw_server/database/models/storage/storage.dart";
import "package:rpmtw_server/handler/minecraft_handler.dart";
import "package:rpmtw_server/routes/base_route.dart";
import "package:rpmtw_server/utilities/api_response.dart";
import "package:rpmtw_server/utilities/data.dart";
import "package:rpmtw_server/utilities/extension.dart";

class MinecraftRoute extends APIRoute {
  @override
  String get routeName => "minecraft";

  @override
  void router(router) {
    router.postRoute("/mod/create", (req, data) async {
      ModRequestBodyParsedResult result =
          await MinecraftHeader.parseModRequestBody(data.fields);

      if (result.name == null || result.name!.isEmpty) {
        return APIResponse.badRequest(message: "Invalid mod name");
      }

      if (result.supportVersions == null || result.supportVersions!.isEmpty) {
        return APIResponse.badRequest(message: "Invalid game version");
      }

      if (result.imageStorageUUID != null) {
        Storage? storage = await Storage.getByUUID(result.imageStorageUUID!);
        if (storage == null) {
          return APIResponse.badRequest(message: "Invalid image storage");
        }
        if (storage.type == StorageType.temp) {
          storage = storage.copyWith(type: StorageType.general);
          await storage.update();
        }
      }

      MinecraftMod mod = await MinecraftHeader.createMod(result);

      WikiChangeLog changeLog = WikiChangeLog(
          uuid: Uuid().v4(),
          type: WikiChangeLogType.addedMod,
          dataUUID: mod.uuid,
          changedData: mod.toMap(),
          time: DateTime.now().toUtc(),
          userUUID: req.user!.uuid);

      await changeLog.insert();

      return APIResponse.success(data: mod.outputMap());
    }, requiredFields: ["name", "supportVersions"], authConfig: AuthConfig());

    router.patchRoute("/mod/edit/<uuid>", (req, data) async {
      MinecraftMod? mod = await MinecraftMod.getByUUID(data.fields["uuid"]!);

      if (mod == null) {
        return APIResponse.badRequest(message: "Mod not found");
      }

      ModRequestBodyParsedResult result =
          await MinecraftHeader.parseModRequestBody(data.fields);

      DateTime time = DateTime.now().toUtc();

      if (result.imageStorageUUID != null) {
        Storage? storage = await Storage.getByUUID(result.imageStorageUUID!);
        if (storage == null) {
          return APIResponse.badRequest(message: "Invalid image storage");
        }
        if (storage.type == StorageType.temp) {
          storage = storage.copyWith(type: StorageType.general);
          await storage.update();
        }
      }

      mod = mod.copyWith(
        name:
            result.name != null && result.name!.isNotEmpty ? result.name : null,
        id: result.id != null && result.id!.isNotEmpty ? result.id : null,
        description:
            result.description != null && result.description!.isNotEmpty
                ? result.description
                : null,
        supportVersions: result.supportVersions,
        relationMods: result.relationMods,
        loader: result.loader,
        integration: result.integration,
        side: result.side,
        lastUpdate: time,
        translatedName: result.translatedName,
        introduction: result.introduction,
        imageStorageUUID: result.imageStorageUUID,
      );

      WikiChangeLog changeLog = WikiChangeLog(
          uuid: Uuid().v4(),
          changelog: data.fields["changelog"],
          type: WikiChangeLogType.editedMod,
          dataUUID: mod.uuid,
          changedData: mod.toMap(),
          time: DateTime.now().toUtc(),
          userUUID: req.user!.uuid);

      await mod.update();
      await changeLog.insert();

      return APIResponse.success(data: mod.outputMap());
    }, authConfig: AuthConfig());

    router.getRoute("/mod/view/<uuid>", (req, data) async {
      String uuid = data.fields["uuid"]!;
      MinecraftMod? mod;
      mod = await MinecraftMod.getByUUID(uuid);
      if (mod == null) {
        return APIResponse.modelNotFound<MinecraftMod>();
      }

      String? _recordViewCount = data.fields["recordViewCount"];
      bool recordViewCount =
          _recordViewCount == null ? false : _recordViewCount.toBool();

      if (recordViewCount &&
          UserViewCountFilter.needUpdateViewCount(req.ip, mod.uuid)) {
        mod = mod.copyWith(viewCount: mod.viewCount + 1);

        // Update view count
        await mod.update();
      }

      return APIResponse.success(data: mod.outputMap());
    });

    router.getRoute("/mod/search", (req, data) async {
      Map<String, dynamic> fields = data.fields;

      String? filter = fields["filter"];
      int? limit =
          fields["limit"] != null ? int.tryParse(fields["limit"]) : null;
      int? skip = fields["skip"] != null ? int.tryParse(fields["skip"]) : null;
      int sort = fields["sort"] != null ? int.tryParse(fields["sort"]) ?? 0 : 0;

      List<MinecraftMod> mods = await MinecraftHeader.searchMods(
          filter: filter, limit: limit, skip: skip, sort: sort);

      return APIResponse.success(data: {
        if (limit != null) "limit": (limit > 50) ? 50 : limit,
        if (skip != null) "skip": skip,
        "mods": mods.map((e) => e.outputMap()).toList()
      });
    });

    /// 從資料庫快取中取得 Minecraft 版本資訊
    router.getRoute("/versions", (req, data) async {
      MinecraftVersionManifest manifest =
          await MinecraftVersionManifest.getFromCache();
      manifest.copyWith(
          manifest: manifest.manifest.copyWith(
              versions: manifest.manifest.versions
                  // 僅輸出正式版
                  .where((v) => v.type == MinecraftVersionType.release)
                  .toList()));
      return APIResponse.success(data: manifest.outputMap());
    });

    router.getRoute("/changelog", (req, data) async {
      Map<String, dynamic> fields = data.fields;

      int? limit =
          fields["limit"] != null ? int.tryParse(fields["limit"]) : null;
      int? skip = fields["skip"] != null ? int.tryParse(fields["skip"]) : null;
      String? dataUUID = fields["dataUUID"];
      String? userUUID = fields["userUUID"];

      List<WikiChangeLog> changelogs = await MinecraftHeader.filterChangelogs(
          limit: limit, skip: skip, dataUUID: dataUUID, userUUID: userUUID);
      List<Map<String, dynamic>> changelogsMap = [];
      for (WikiChangeLog log in changelogs) {
        changelogsMap.add(await log.output());
      }

      return APIResponse.success(data: {
        if (limit != null) "limit": (limit > 50) ? 50 : limit,
        if (skip != null) "skip": skip,
        "changelogs": changelogsMap
      });
    });
  }
}
