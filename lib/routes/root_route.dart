import 'package:rpmtw_server/routes/curseforge_route.dart';
import 'package:rpmtw_server/routes/minecraft_route.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../utilities/data.dart';
import '../utilities/extension.dart';
import 'base_route.dart';
import 'package:rpmtw_server/routes/auth_route.dart';
import 'package:rpmtw_server/routes/storage_route.dart';

class RootRoute implements BaseRoute {
  @override
  Router get router {
    final Router router = Router();

    router.mount('/auth/', AuthRoute().router);
    router.mount('/storage/', StorageRoute().router);
    router.mount('/minecraft/', MinecraftRoute().router);
    router.mount('/curseforge/', CurseForgeRoute().router);

    router.get('/', (Request req) async {
      return ResponseExtension.success(data: {"message": "Hello RPMTW World"});
    });

    router.get('/ip', (Request req) async {
      return ResponseExtension.success(data: {"ip": req.ip});
    });

    return router;
  }
}
