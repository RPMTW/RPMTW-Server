import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:rpmtw_server/database/database.dart';
import 'package:rpmtw_server/handler/auth_handler.dart';
import 'package:rpmtw_server/routes/root_route.dart';

import 'package:rpmtw_server/utilities/data.dart';
import 'package:rpmtw_server/utilities/utility.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_rate_limiter/shelf_rate_limiter.dart';

HttpServer? server;

void main(List<String> args) => run();

Future<void> run() async {
  await Utility.hotReload();
  Data.init();
  loggerNoStack.i("connecting to database");
  await DataBase.init();
  final InternetAddress ip = InternetAddress.anyIPv4;

  final memoryStorage = MemStorage();

  /// 一分鐘內最多請求100次
  final rateLimiter = ShelfRateLimiter(
      storage: memoryStorage,
      duration: Duration(seconds: 60),
      maxRequests: 100);

  final Handler _handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(rateLimiter.rateLimiter())
      .addMiddleware(AuthHandler.authorizationToken())
      .addHandler(RootRoute().router);

  final int port = int.parse(env['API_PORT'] ?? '8080');
  server = await serve(_handler, ip, port);
  loggerNoStack.i('Server listening on port http://${ip.host}:${server!.port}');
}
