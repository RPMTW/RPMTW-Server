import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version_manifest.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';
import 'package:rpmtw_server/database/models/minecraft/rpmwiki/wiki_change_log.dart';
import 'package:rpmtw_server/database/models/storage/storage.dart';
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

        ModRequestBodyParsedResult result =
            await MinecraftHeader.parseModRequestBody(data);

        if (result.name == null || result.name!.isEmpty) {
          return ResponseExtension.badRequest(message: "Invalid mod name");
        }

        if (result.supportVersions == null || result.supportVersions!.isEmpty) {
          return ResponseExtension.badRequest(message: "Invalid game version");
        }

        if (result.imageStorageUUID != null) {
          Storage? storage = await Storage.getByUUID(result.imageStorageUUID!);
          if (storage == null) {
            return ResponseExtension.badRequest(
                message: "Invalid image storage");
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

        return ResponseExtension.success(data: mod.outputMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    router.patch("/mod/edit/<uuid>", (Request req) async {
      try {
        Map<String, dynamic> data = await req.data;

        MinecraftMod? mod = await MinecraftMod.getByUUID(req.params["uuid"]!);

        if (mod == null) {
          return ResponseExtension.badRequest(message: "Mod not found");
        }

        ModRequestBodyParsedResult result =
            await MinecraftHeader.parseModRequestBody(data);

        DateTime time = DateTime.now().toUtc();

        if (result.imageStorageUUID != null) {
          Storage? storage = await Storage.getByUUID(result.imageStorageUUID!);
          if (storage == null) {
            return ResponseExtension.badRequest(
                message: "Invalid image storage");
          }
          if (storage.type == StorageType.temp) {
            storage = storage.copyWith(type: StorageType.general);
            await storage.update();
          }
        }

        mod = mod.copyWith(
          name: result.name != null && result.name!.isNotEmpty
              ? result.name
              : null,
          id: result.id != null && result.id!.isNotEmpty ? result.id : null,
          description:
              result.description != null && result.description!.isNotEmpty
                  ? result.description
                  : null,
          supportVersions: result.supportVersions,
          relationMods: result.relationMods,
          integration: result.integration,
          side: result.side,
          lastUpdate: time,
          translatedName: result.translatedName,
          introduction: result.introduction,
          imageStorageUUID: result.imageStorageUUID,
        );

        WikiChangeLog changeLog = WikiChangeLog(
            uuid: Uuid().v4(),
            type: WikiChangeLogType.editedMod,
            dataUUID: mod.uuid,
            changedData: mod.toMap(),
            time: DateTime.now().toUtc(),
            userUUID: req.user!.uuid);

        await mod.update();
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

        String? _recordViewCount = req.url.queryParameters['recordViewCount'];
        bool recordViewCount =
            _recordViewCount == null ? false : _recordViewCount.toBool();

        if (recordViewCount &&
            UserViewCountFilter.needUpdateViewCount(req.ip, mod.uuid)) {
          mod = mod.copyWith(viewCount: mod.viewCount + 1);

          /// Update view count
          await mod.update();
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
        int sort = query['sort'] != null ? int.tryParse(query['sort']) ?? 0 : 0;

        List<MinecraftMod> mods = await MinecraftHeader.searchMods(
            filter: filter, limit: limit, skip: skip, sort: sort);

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
        List<Map<String, dynamic>> changelogsMap = [];
        for (WikiChangeLog log in changelogs) {
          changelogsMap.add(await log.output());
        }

        return ResponseExtension.success(data: {
          if (limit != null) "limit": (limit > 50) ? 50 : limit,
          if (skip != null) "skip": skip,
          "changelogs": changelogsMap
        });
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }
}
