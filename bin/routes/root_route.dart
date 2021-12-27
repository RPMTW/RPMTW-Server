import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../utilities/data.dart';
import '../utilities/extension.dart';
import 'base_route.dart';

class RootRoute implements BaseRoute {
  @override
  Router get router {
    final Router router = Router();

    router.get('/', (Request req) async {
      return Response.ok('Hello RPMTW World!');
    });

    router.get('/ip', (Request req) async {
      try {
        HttpConnectionInfo connectionInfo =
            req.context['shelf.io.connection_info'] as HttpConnectionInfo;
        String ip = connectionInfo.remoteAddress.address;
        return Response.ok(ip);
      } catch (e) {
        logger.e(e);
        return ResponseExtension.internalServerError();
      }
    });

    return router;
  }
}
