import "package:rpmtw_server/database/models/cosmic_chat/cosmic_chat_info.dart";
import "package:rpmtw_server/database/models/cosmic_chat/cosmic_chat_message.dart";
import "package:rpmtw_server/handler/cosmic_chat_handler.dart";
import 'package:rpmtw_server/routes/api_route.dart';
import "package:rpmtw_server/utilities/api_response.dart";
import "package:rpmtw_server/utilities/extension.dart";

class CosmicChatRoute extends APIRoute {
  @override
  String get routeName => "cosmic-chat";

  @override
  void router(router) {
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
  }
}
