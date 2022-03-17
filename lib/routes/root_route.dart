import 'package:rpmtw_server/routes/cosmic_chat_route.dart';
import 'package:rpmtw_server/routes/curseforge_route.dart';
import 'package:rpmtw_server/routes/minecraft_route.dart';
import 'package:rpmtw_server/routes/translate_route.dart';
import 'package:rpmtw_server/utilities/api_response.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../utilities/extension.dart';
import 'base_route.dart';
import 'package:rpmtw_server/routes/auth_route.dart';
import 'package:rpmtw_server/routes/storage_route.dart';

class RootRoute implements APIRoute {
  @override
  Router get router {
    final Router router = Router();

    router.mount('/auth/', AuthRoute().router);
    router.mount('/storage/', StorageRoute().router);
    router.mount('/minecraft/', MinecraftRoute().router);
    router.mount('/curseforge/', CurseForgeRoute().router);
    router.mount('/cosmic-chat/', CosmicChatRoute().router);
    router.mount('/translate/', TranslateRoute().router);

    router.getRoute('/', (Request req) async {
      return APIResponse.success(data: {"message": "Hello RPMTW World"});
    });

    router.getRoute('/ip', (Request req) async {
      return APIResponse.success(data: {"ip": req.ip});
    });

    return router;
  }
}
