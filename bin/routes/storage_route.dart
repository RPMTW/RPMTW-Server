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
      return ResponseExtension.success(data: {});
    });

    return router;
  }
}
