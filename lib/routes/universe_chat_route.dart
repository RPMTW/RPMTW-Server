import 'package:rpmtw_server/database/models/universe_chat/universe_chat_info.dart';
import 'package:rpmtw_server/database/models/universe_chat/universe_chat_message.dart';
import 'package:rpmtw_server/handler/universe_chat_handler.dart';
import 'package:rpmtw_server/routes/api_route.dart';
import 'package:rpmtw_server/utilities/api_response.dart';
import 'package:rpmtw_server/utilities/extension.dart';

class UniverseChatRoute extends APIRoute {
  @override
  String get routeName => 'universe-chat';

  @override
  void router(router) {
    router.getRoute('/view/<uuid>', (req, data) async {
      final String uuid = data.fields['uuid']!;
      UniverseChatMessage? message = await UniverseChatMessage.getByUUID(uuid);

      if (message == null) {
        return APIResponse.badRequest(message: 'Message not found');
      }

      return APIResponse.success(data: message.outputMap());
    });

    router.getRoute('/info', (req, data) async {
      int online = UniverseChatHandler.onlineUsers;
      UniverseChatInfo info =
          UniverseChatInfo(onlineUsers: online, protocolVersion: 1);

      return APIResponse.success(data: info.toMap());
    });
  }
}
