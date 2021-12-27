import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'routes/auth_route.dart';
import 'routes/root_route.dart';
import 'routes/storage_route.dart';
import 'utilities/data.dart';
import 'utilities/utility.dart';
import 'database/database.dart';

final Router _router = Router()
  ..mount('/', RootRoute().router)
  ..mount('/auth/', AuthRoute().router)
  ..mount('/storage/', StorageRoute().router);

void main(List<String> args) async {
  Data.init();
  print("connecting to database");
  await DataBase.init();
  final InternetAddress ip = InternetAddress.anyIPv4;

  final Handler _handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router);

  final int port = int.parse(env['API_PORT'] ?? '8080');
  final HttpServer server = await serve(_handler, ip, port);
  print('Server listening on port http://${ip.host}:${server.port}');

  await Utility.hotReload();
}
