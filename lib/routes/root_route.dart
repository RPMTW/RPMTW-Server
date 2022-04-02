import 'package:rpmtw_server/routes/comment_route.dart';
import 'package:rpmtw_server/routes/universe_chat_route.dart';
import 'package:rpmtw_server/routes/curseforge_route.dart';
import 'package:rpmtw_server/routes/minecraft_route.dart';
import 'package:rpmtw_server/routes/translate_route.dart';
import 'package:rpmtw_server/utilities/api_response.dart';
import 'package:shelf_router/shelf_router.dart';

import '../utilities/extension.dart';
import 'package:rpmtw_server/routes/auth_route.dart';
import 'package:rpmtw_server/routes/storage_route.dart';

class RootRoute {
  Router get router {
    final Router router = Router();
    AuthRoute().register(router);
    StorageRoute().register(router);
    MinecraftRoute().register(router);
    CurseForgeRoute().register(router);
    UniverseChatRoute().register(router);
    TranslateRoute().register(router);
    CommentRoute().register(router);

    router.getRoute('/', (req, data) async {
      return APIResponse.success(data: {'message': 'Hello RPMTW World'});
    });

    router.getRoute('/ip', (req, data) async {
      return APIResponse.success(data: {'ip': req.ip});
    });

    return router;
  }
}
