import "package:rpmtw_server/database/models/cosmic_chat/cosmic_chat_info.dart";
import "package:rpmtw_server/database/models/cosmic_chat/cosmic_chat_message.dart";
import "package:rpmtw_server/handler/cosmic_chat_handler.dart";
import "package:rpmtw_server/routes/base_route.dart";
import "package:rpmtw_server/utilities/api_response.dart";
import "package:rpmtw_server/utilities/extension.dart";
import "package:shelf_router/shelf_router.dart";

class CosmicChatRoute implements APIRoute {
  @override
  Router get router {
    final Router router = Router();

    router.getRoute("/view/<uuid>", (req, data) async {
      final String uuid = data.fields["uuid"]!;
      CosmicChatMessage? message = await CosmicChatMessage.getByUUID(uuid);

      if (message == null) {
        return APIResponse.badRequest(message: "Message not found");
      }

      return APIResponse.success(data: message.outputMap());
    });

    router.getRoute("/info", (req, data) async {
      int online = CosmicChatHandler.onlineUsers;
      CosmicChatInfo info =
          CosmicChatInfo(onlineUsers: online, protocolVersion: 1);

      return APIResponse.success(data: info.toMap());
    });

    return router;
  }
}
