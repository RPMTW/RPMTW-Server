import "dart:io";

import "package:dotenv/dotenv.dart";
import "package:rpmtw_server/database/database.dart";
import "package:rpmtw_server/handler/auth_handler.dart";
import "package:rpmtw_server/handler/cosmic_chat_handler.dart";
import "package:rpmtw_server/routes/root_route.dart";

import "package:rpmtw_server/utilities/data.dart";
import "package:shelf/shelf.dart";
import "package:shelf/shelf_io.dart";
import "package:shelf_cors_headers/shelf_cors_headers.dart";
import "package:shelf_rate_limiter/shelf_rate_limiter.dart";

import "../test/test_utility.dart";

HttpServer? server;

Future<void> main(List<String> args) async {
  if (args.contains("RPMTW_SERVER_TEST_MODE=TRUE")) {
    loggerNoStack.i("Enabled test mode");
    kTestMode = true;
    await run(envParser: const TestEnvParser());
  } else {
    await run();
  }
}

Future<void> run({Parser? envParser}) async {
  Data.init(envParser: envParser);
  loggerNoStack.i("connecting to database");
  await DataBase.init();
  final InternetAddress ip = InternetAddress.anyIPv4;

  final memoryStorage = MemStorage();

  /// 一分鐘內最多請求100次
  final rateLimiter = ShelfRateLimiter(
      storage: memoryStorage,
      duration: Duration(seconds: 60),
      maxRequests: 100);

  // final overrideHeaders = {
  //   ACCESS_CONTROL_ALLOW_ORIGIN: "*",
  // };

  final Handler _handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(rateLimiter.rateLimiter())
      .addMiddleware(AuthHandler.handleBanIP())
      .addHandler(RootRoute().router);

  final int port = int.parse(env["API_PORT"] ?? "8080");
  server = await serve(_handler, ip, port);
  server?.autoCompress = true;
  loggerNoStack
      .i("API Server listening on port http://${ip.host}:${server!.port}");

  await CosmicChatHandler().init();
}
