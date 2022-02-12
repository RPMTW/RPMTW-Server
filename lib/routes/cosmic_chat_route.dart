import 'package:rpmtw_server/database/models/cosmic_chat/cosmic_chat_message.dart';
import 'package:rpmtw_server/routes/base_route.dart';
import 'package:rpmtw_server/utilities/data.dart';
import 'package:rpmtw_server/utilities/extension.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class CosmicChatRoute implements BaseRoute {
  @override
  Router get router {
    final Router router = Router();

    router.get('/view/<uuid>', (Request req) async {
      try {
        final String uuid = req.params['uuid']!;
        CosmicChatMessage? message = await CosmicChatMessage.getByUUID(uuid);

        if (message == null) {
          return ResponseExtension.badRequest(message: "Message not found");
        }

        return ResponseExtension.success(data: message.outputMap());
      } catch (e, stack) {
        logger.e(e, null, stack);
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }
}
