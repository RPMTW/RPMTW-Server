import 'dart:convert';
import 'dart:io';

import 'package:rpmtw_server/routes/minecraft_route.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../database/models/auth/user.dart';
import '../utilities/data.dart';
import '../utilities/extension.dart';
import 'base_route.dart';
import 'package:rpmtw_server/routes/auth_route.dart';
import 'package:rpmtw_server/routes/storage_route.dart';

class RootRoute implements BaseRoute {
  @override
  Router get router {
    final Router router = Router();

    router.mount('/auth/', AuthRoute().router);
    router.mount('/storage/', StorageRoute().router);
    router.mount('/minecraft/', MinecraftRoute().router);

    router.get('/', (Request req) async {
      return Response.ok(
        'Hello RPMTW World!',
      );
    });

    router.get('/ip', (Request req) async {
      try {
        return Response.ok(req.ip);
      } catch (e) {
        logger.e(e);
        return ResponseExtension.internalServerError();
      }
    });

    return router;
  }
}

extension RequestUserExtension on Request {
  String get ip {
    String? xForwardedFor = headers['X-Forwarded-For'];
    if (xForwardedFor != null && kTestMode) {
      return xForwardedFor;
    } else {
      HttpConnectionInfo connectionInfo =
          context['shelf.io.connection_info'] as HttpConnectionInfo;
      InternetAddress internetAddress = connectionInfo.remoteAddress;
      return internetAddress.address;
    }
  }

  bool isAuthenticated() {
    return context['isAuthenticated'] == true && context['user'] is User;
  }

  User? get user {
    try {
      return context['user'] as User;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> get data async {
    return json.decode(await readAsString());
  }
}
