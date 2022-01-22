import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version_manifest.dart';
import 'package:rpmtw_server/database/models/minecraft/relation_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_integration.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_side.dart';
import 'package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_change_log.dart';
import 'package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_mod_data.dart';
import 'package:rpmtw_server/handler/minecraft_handler.dart';
import 'package:rpmtw_server/routes/base_route.dart';
import 'package:rpmtw_server/utilities/data.dart';
import 'package:rpmtw_server/utilities/extension.dart';
import 'package:rpmtw_server/utilities/messages.dart';
import 'package:rpmtw_server/utilities/utility.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:rpmtw_server/routes/root_route.dart';

class MinecraftRoute implements BaseRoute {
  @override
  Router get router {
    Router router = Router();

    router.post("/mod/create", (Request req) async {
      try {
        Map<String, dynamic> data = await req.data;
        bool validateFields =
            Utility.validateRequiredFields(data, ["name", "supportVersions"]);

        if (!validateFields) {
          return ResponseExtension.badRequest(
              message: Messages.missingRequiredFields);
        }

        String name = data['name'];

        List<MinecraftVersion> allVersions =
            (await MinecraftVersionManifest.getFromCache()).manifest.versions;
        List<MinecraftVersion> supportedVersions;
        try {
          supportedVersions = List<MinecraftVersion>.from(
              data['supportVersions']
                  ?.map((x) => allVersions.firstWhere((e) => e.id == x)));
        } catch (e) {
          return ResponseExtension.badRequest(message: "Invalid game version");
        }

        String? id = data['id'];
        String? description = data['description'];
        List<RelationMod>? relationMods = data['relationMods'] != null
            ? List<RelationMod>.from(
                data['relationMods']!.map((x) => RelationMod.fromMap(x)))
            : null;
        ModIntegrationPlatform? integration = data['integration'] != null
            ? ModIntegrationPlatform.fromMap(data['integration'])
            : null;
        List<ModSide>? side = data['side'] != null
            ? List<ModSide>.from(
                data['side']!.map((x) => ModSide.fromMap(x)).toList())
            : null;
        List<ModLoader>? loader = data['loader'] != null
            ? List<ModLoader>.from(
                data['loader']?.map((x) => ModLoader.values.byName(x)))
            : null;

        MinecraftMod mod = await MinecraftHeader.createMod(
            name: name,
            id: id,
            supportVersions: supportedVersions,
            description: description,
            relationMods: relationMods,
            integration: integration,
            side: side,
            loader: loader);

        WikiChangeLog changeLog = WikiChangeLog(
            uuid: Uuid().v4(),
            type: WikiChangeLogType.addedMod,
            dataUUID: mod.uuid,
            time: DateTime.now(),
            userUUID: req.user!.uuid);

        await changeLog.insert();

        return ResponseExtension.success(data: mod.outputMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    router.get("/mod/view/<uuid>", (Request req) async {
      try {
        bool validateFields =
            Utility.validateRequiredFields(req.params, ["uuid"]);
        if (!validateFields) {
          return ResponseExtension.badRequest(
              message: Messages.missingRequiredFields);
        }

        String uuid = req.params['uuid']!;
        MinecraftMod? mod;
        mod = await MinecraftMod.getByUUID(uuid);
        if (mod == null) {
          return ResponseExtension.notFound("Minecraft mod not found");
        }
        return ResponseExtension.success(data: mod.outputMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    router.get("/mod/search", (Request req) async {
      try {
        Map<String, dynamic> query = req.url.queryParameters;

        String? filter = query['filter'];
        int? limit =
            query['limit'] != null ? int.tryParse(query['limit']) : null;
        int? skip = query['skip'] != null ? int.tryParse(query['skip']) : null;

        List<MinecraftMod> mods = await MinecraftHeader.searchMods(
            filter: filter, limit: limit, skip: skip);

        return ResponseExtension.success(data: {
          if (limit != null) "limit": (limit > 50) ? 50 : limit,
          if (skip != null) "skip": skip,
          "mods": mods.map((e) => e.outputMap()).toList()
        });
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    router.post("/mod/wiki/create", (Request req) async {
      try {
        Map<String, dynamic> data = await req.data;
        bool validateFields = Utility.validateRequiredFields(data, ["modUUID"]);
        if (!validateFields) {
          return ResponseExtension.badRequest(
              message: Messages.missingRequiredFields);
        }

        String modUUID = data['modUUID']!;
        String? translatedName = data['translatedName'];
        String? introduction = data['introduction'];
        String? imageStorageUUID = data['imageStorageUUID'];

        MinecraftMod? mod = await MinecraftMod.getByUUID(modUUID);

        if (mod == null) {
          return ResponseExtension.notFound(
              "Can't find this Minecraft mod ($modUUID)");
        }

        WikiModData modData = WikiModData(
            uuid: Uuid().v4(),
            modUUID: modUUID,
            translatedName: translatedName,
            introduction: introduction,
            imageStorageUUID: imageStorageUUID);

        WikiChangeLog changeLog = WikiChangeLog(
            uuid: Uuid().v4(),
            type: WikiChangeLogType.addedWikiModData,
            dataUUID: modData.uuid,
            time: DateTime.now(),
            userUUID: req.user!.uuid);

        await changeLog.insert();
        await modData.insert();

        return ResponseExtension.success(data: modData.outputMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    router.get("/mod/wiki/view/<uuid>", (Request req) async {
      try {
        bool validateFields =
            Utility.validateRequiredFields(req.params, ["uuid"]);
        if (!validateFields) {
          return ResponseExtension.badRequest(
              message: Messages.missingRequiredFields);
        }

        String uuid = req.params['uuid']!;
        WikiModData? modData = await WikiModData.getByUUID(uuid);
        if (modData == null) {
          return ResponseExtension.notFound("Wiki mod data not found");
        }

        if (UserViewCountFilter.needUpdateViewCount(req.ip, modData.uuid)) {
          modData = modData.copyWith(viewCount: modData.viewCount + 1);

          /// Update view count
          await modData.update();
        }

        return ResponseExtension.success(data: modData.outputMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    router.get("/mod/wiki/view-by-mod-uuid/<modUUID>", (Request req) async {
      try {
        bool validateFields =
            Utility.validateRequiredFields(req.params, ["modUUID"]);
        if (!validateFields) {
          return ResponseExtension.badRequest(
              message: Messages.missingRequiredFields);
        }

        String modUUID = req.params['modUUID']!;
        MinecraftMod? mod = await MinecraftMod.getByUUID(modUUID);
        if (mod == null) {
          return ResponseExtension.notFound("Minecraft mod not found");
        }

        WikiModData? modData = await WikiModData.getByModUUID(modUUID);
        if (modData == null) {
          modData = WikiModData(uuid: Uuid().v4(), modUUID: modUUID);
          await modData.insert();
        }

        if (UserViewCountFilter.needUpdateViewCount(req.ip, modData.uuid)) {
          modData = modData.copyWith(viewCount: modData.viewCount + 1);

          /// Update view count
          await modData.update();
        }

        return ResponseExtension.success(data: modData.outputMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    /// 從資料庫快取中取得 Minecraft 版本資訊
    router.get("/versions", (Request req) async {
      try {
        MinecraftVersionManifest manifest =
            await MinecraftVersionManifest.getFromCache();
        manifest.copyWith(
            manifest: manifest.manifest.copyWith(
                versions: manifest.manifest.versions
                    // 僅輸出正式版
                    .where((v) => v.type == MinecraftVersionType.release)
                    .toList()));
        return ResponseExtension.success(data: manifest.outputMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    router.get("/changelog", (Request req) async {
      try {
        Map<String, dynamic> query = req.url.queryParameters;

        int? limit =
            query['limit'] != null ? int.tryParse(query['limit']) : null;
        int? skip = query['skip'] != null ? int.tryParse(query['skip']) : null;

        List<WikiChangeLog> changelogs =
            await MinecraftHeader.filterChangelogs(limit: limit, skip: skip);

        return ResponseExtension.success(data: {
          if (limit != null) "limit": (limit > 50) ? 50 : limit,
          if (skip != null) "skip": skip,
          "changelogs": changelogs.map((e) => e.outputMap()).toList()
        });
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }
}
