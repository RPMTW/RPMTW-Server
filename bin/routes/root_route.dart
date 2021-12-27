import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../utilities/extension.dart';

class RootRoute {
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
        return ResponseExtension.internalServerError();
      }
    });

    return router;
  }
}
