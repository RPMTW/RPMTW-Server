import 'package:rpmtw_server/database/models/minecraft/relation_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_mod.dart';
import 'package:rpmtw_server/database/models/minecraft/minecraft_version.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_integration.dart';
import 'package:rpmtw_server/database/models/minecraft/mod_side.dart';
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
        bool validateFields = Utility.validateRequiredFields(
            data, ["name", "id", "supportVersions"]);

        if (!validateFields) {
          return ResponseExtension.badRequest(
              message: Messages.missingRequiredFields);
        }

        String name = data['name'];
        String id = data['id'];
        List<MinecraftVersion> supportedVersions = List<MinecraftVersion>.from(
            data['supportVersions']?.map((x) => MinecraftVersion.fromMap(x)));

        String? description = data['description'];
        List<RelationMod>? relationMods = data['relationMods'] != null
            ? List<RelationMod>.from(
                data['relationMods']!.map((x) => RelationMod.fromMap(x)))
            : null;
        ModIntegration? integration = data['integration'] != null
            ? ModIntegration.fromMap(data['integration'])
            : null;
        List<ModSide>? side = data['side'] != null
            ? data['side']!.map((x) => ModSide.fromMap(x))?.toList()
            : null;

        MinecraftMod mod = await MinecraftHeader.createMod(
          name: name,
          id: id,
          supportVersions: supportedVersions,
          description: description,
          relationMods: relationMods,
          integration: integration,
          side: side,
        );

        return ResponseExtension.success(data: mod.outputMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    router.get("/mod/<uuid>", (Request req) async {
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

    return router;
  }
}
