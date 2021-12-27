import 'package:shelf/shelf.dart';
import 'package:shelf_router/src/router.dart';

import '../utilities/extension.dart';
import 'base_route.dart';

class StorageRoute implements BaseRoute {
  @override
  Router get router {
    final Router router = Router();

    // TODO: implement temp storage
    router.get("/create", (Request req) async {
      try {
         
        return ResponseExtension.success(data: {});
      } catch (e) {
        return ResponseExtension.badRequest();
      }
    });

    return router;
  }
}
