import 'package:rpmtw_server/database/models/cosmic_chat/cosmic_chat_info.dart';
import 'package:rpmtw_server/database/models/cosmic_chat/cosmic_chat_message.dart';
import 'package:rpmtw_server/handler/cosmic_chat_handler.dart';
import 'package:rpmtw_server/routes/base_route.dart';
import 'package:rpmtw_server/utilities/extension.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class CosmicChatRoute implements BaseRoute {
  @override
  Router get router {
    final Router router = Router();

    router.getRoute('/view/<uuid>', (Request req) async {
      final String uuid = req.params['uuid']!;
      CosmicChatMessage? message = await CosmicChatMessage.getByUUID(uuid);

      if (message == null) {
        return ResponseExtension.badRequest(message: "Message not found");
      }

      return ResponseExtension.success(data: message.outputMap());
    });

    router.getRoute("/info", (Request req) async {
      int online = CosmicChatHandler.onlineUsers;
      CosmicChatInfo info =
          CosmicChatInfo(onlineUsers: online, protocolVersion: 1);

      return ResponseExtension.success(data: info.toMap());
    });

    return router;
  }
}
