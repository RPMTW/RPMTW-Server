import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_rate_limiter/shelf_rate_limiter.dart';
import 'package:shelf_router/shelf_router.dart';

import 'handler/auth_handler.dart';
import 'routes/auth_route.dart';
import 'routes/root_route.dart';
import 'routes/storage_route.dart';
import 'utilities/data.dart';
import 'database/database.dart';

late HttpServer server;

final Router _router = Router()
  ..mount('/', RootRoute().router)
  ..mount('/auth/', AuthRoute().router)
  ..mount('/storage/', StorageRoute().router);

void main(List<String> args) => run();

Future<void> run() async {
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
      .addHandler(_router);

  final int port = int.parse(env['API_PORT'] ?? '8080');
  server = await serve(_handler, ip, port);
  loggerNoStack.i('Server listening on port http://${ip.host}:${server.port}');

  // await Utility.hotReload();
}
